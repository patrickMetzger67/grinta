package io.grinta.app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "asi_usb"
    private val actionUsbPermission = "io.grinta.app.USB_PERMISSION"

    private lateinit var usbManager: UsbManager

    private val discoveredDevices = ConcurrentHashMap<String, UsbDevice>()
    private val connections = ConcurrentHashMap<String, UsbDeviceConnection>()
    private val claimedInterfaces = ConcurrentHashMap<String, UsbInterface>()

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionDeviceId: String? = null

    private val usbPermissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != actionUsbPermission) return

            val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
            }

            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            val result = pendingPermissionResult
            val expectedDeviceId = pendingPermissionDeviceId

            pendingPermissionResult = null
            pendingPermissionDeviceId = null

            if (result == null || expectedDeviceId == null) return

            if (device == null) {
                result.error("USB_PERMISSION_ERROR", "No USB device returned", null)
                return
            }

            if (device.deviceName != expectedDeviceId) {
                result.error(
                    "USB_PERMISSION_ERROR",
                    "Permission response does not match requested device",
                    null
                )
                return
            }

            if (granted) {
                result.success(true)
            } else {
                result.error("USB_PERMISSION_DENIED", "USB permission denied", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

        val filter = IntentFilter(actionUsbPermission)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbPermissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(usbPermissionReceiver, filter)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "listDevices" -> {
                            val vendorId = call.argument<Int>("vendorId")!!
                            val productId = call.argument<Int>("productId")!!
                            result.success(listDevices(vendorId, productId))
                        }

                        "hasPermission" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            result.success(hasPermission(deviceId))
                        }

                        "requestPermission" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            requestPermission(deviceId, result)
                        }

                        "open" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            val interfaceNumber = call.argument<Int>("interfaceNumber")!!
                            openDevice(deviceId, interfaceNumber)
                            result.success(true)
                        }

                        "close" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            closeDevice(deviceId)
                            result.success(true)
                        }

                        "write" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            val endpointAddress = call.argument<Int>("endpointAddress")!!
                            val data = call.argument<ByteArray>("data")!!
                            write(deviceId, endpointAddress, data)
                            result.success(true)
                        }

                        "read" -> {
                            val deviceId = call.argument<String>("deviceId")!!
                            val endpointAddress = call.argument<Int>("endpointAddress")!!
                            val length = call.argument<Int>("length")!!
                            result.success(read(deviceId, endpointAddress, length))
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("USB_ERROR", e.message, null)
                }
            }

        GrintaCalendarChannel.register(flutterEngine, this)
        PlayerDetectionChannel.register(flutterEngine)
        GrintaHealthConnectChannel.register(flutterEngine, this)
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(usbPermissionReceiver)
        } catch (_: Exception) {
        }

        for ((deviceId, _) in connections) {
            closeDevice(deviceId)
        }

        super.onDestroy()
    }

    private fun listDevices(vendorId: Int, productId: Int): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()

        for (device in usbManager.deviceList.values) {
            if (device.vendorId == vendorId && device.productId == productId) {
                discoveredDevices[device.deviceName] = device

                result.add(
                    mapOf(
                        "id" to device.deviceName,
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "productName" to device.productName
                    )
                )
            }
        }

        return result
    }

    private fun hasPermission(deviceId: String): Boolean {
        val device = discoveredDevices[deviceId] ?: throw Exception("Device not found")
        return usbManager.hasPermission(device)
    }

    private fun requestPermission(deviceId: String, result: MethodChannel.Result) {
        val device = discoveredDevices[deviceId] ?: throw Exception("Device not found")

        if (usbManager.hasPermission(device)) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("USB_PERMISSION_BUSY", "Another permission request is already pending", null)
            return
        }

        pendingPermissionResult = result
        pendingPermissionDeviceId = deviceId

        val flags = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE

            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                PendingIntent.FLAG_UPDATE_CURRENT

            else -> 0
        }

        val permissionIntent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(actionUsbPermission),
            flags
        )

        usbManager.requestPermission(device, permissionIntent)
    }

    private fun openDevice(deviceId: String, interfaceNumber: Int) {
        if (connections.containsKey(deviceId)) {
            return
        }

        val device = discoveredDevices[deviceId] ?: throw Exception("Device not found")

        if (!usbManager.hasPermission(device)) {
            throw Exception("USB permission not granted")
        }

        val connection = usbManager.openDevice(device) ?: throw Exception("Cannot open device")

        if (interfaceNumber >= device.interfaceCount) {
            connection.close()
            throw Exception("Interface $interfaceNumber not found")
        }

        val usbInterface = device.getInterface(interfaceNumber)
        val claimed = connection.claimInterface(usbInterface, true)

        if (!claimed) {
            connection.close()
            throw Exception("Cannot claim interface $interfaceNumber")
        }

        connections[deviceId] = connection
        claimedInterfaces[deviceId] = usbInterface
    }

    private fun closeDevice(deviceId: String) {
        val connection = connections.remove(deviceId)
        val usbInterface = claimedInterfaces.remove(deviceId)

        if (connection != null && usbInterface != null) {
            try {
                connection.releaseInterface(usbInterface)
            } catch (_: Exception) {
            }
        }

        try {
            connection?.close()
        } catch (_: Exception) {
        }
    }

    private fun findEndpoint(
        deviceId: String,
        endpointAddress: Int,
        direction: Int
    ): UsbEndpoint {
        val usbInterface = claimedInterfaces[deviceId]
            ?: throw Exception("No claimed interface for device")

        for (i in 0 until usbInterface.endpointCount) {
            val endpoint = usbInterface.getEndpoint(i)
            if (endpoint.address == endpointAddress && endpoint.direction == direction) {
                return endpoint
            }
        }

        throw Exception("Endpoint 0x${endpointAddress.toString(16)} not found")
    }

    private fun write(deviceId: String, endpointAddress: Int, data: ByteArray) {
        val connection = connections[deviceId] ?: throw Exception("Connection not open")
        val endpoint = findEndpoint(deviceId, endpointAddress, UsbConstants.USB_DIR_OUT)

        val transferred = connection.bulkTransfer(endpoint, data, data.size, 5000)
        if (transferred <= 0) {
            throw Exception("USB write failed")
        }
    }

    private fun read(deviceId: String, endpointAddress: Int, length: Int): ByteArray {
        val connection = connections[deviceId] ?: throw Exception("Connection not open")
        val endpoint = findEndpoint(deviceId, endpointAddress, UsbConstants.USB_DIR_IN)

        val buffer = ByteArray(length)
        val transferred = connection.bulkTransfer(endpoint, buffer, length, 5000)

        if (transferred < 0) {
            throw Exception("USB read failed")
        }

        return buffer.copyOf(transferred)
    }
}
