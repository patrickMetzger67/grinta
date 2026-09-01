const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  buildTemplatePayload,
  digitsOnlyPhone,
} = require('./send_whatsapp');

describe('digitsOnlyPhone', () => {
  it('strips plus and non-digits', () => {
    assert.equal(digitsOnlyPhone('+33 6 12-34-56-78'), '33612345678');
  });

  it('rejects short values', () => {
    assert.equal(digitsOnlyPhone('+331'), null);
    assert.equal(digitsOnlyPhone(''), null);
    assert.equal(digitsOnlyPhone(null), null);
  });
});

describe('buildTemplatePayload', () => {
  it('builds Meta Cloud API template payload with body params', () => {
    const payload = buildTemplatePayload({
      to: '33612345678',
      templateName: 'member_invitation',
      languageCode: 'fr',
      bodyParameters: [
        'Grinta Performance',
        'GT1234',
        'https://grinta.io/invite?code=GT1234',
      ],
    });

    assert.equal(payload.messaging_product, 'whatsapp');
    assert.equal(payload.to, '33612345678');
    assert.equal(payload.type, 'template');
    assert.equal(payload.template.name, 'member_invitation');
    assert.equal(payload.template.language.code, 'fr');
    assert.equal(payload.template.components.length, 1);
    assert.equal(payload.template.components[0].type, 'body');
    assert.equal(payload.template.components[0].parameters.length, 3);
    assert.equal(
      payload.template.components[0].parameters[1].text,
      'GT1234',
    );
  });

  it('omits components when no body parameters', () => {
    const payload = buildTemplatePayload({
      to: '33612345678',
      templateName: 'member_invitation',
      languageCode: 'en',
      bodyParameters: [],
    });
    assert.equal(payload.template.components, undefined);
  });
});
