var getBindProp;

({getBindProp} = require('../dom-util'));

module.exports = function(binding, eventName) {
  return function(comp) {
    var bindProp, props;
    ({props} = comp);
    bindProp = getBindProp(comp);
    comp.setProp(bindProp, binding, props, 'Props');
    comp.bind(eventName || 'onchange', (function(event, node) {
      return binding(node[bindProp]);
    }), 'before');
    return comp;
  };
};
