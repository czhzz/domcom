###*test-directive
###

{expect, iit, idescribe, nit, ndescribe, ddescribe} = require('bdd-test-helper')

{
Component, list, func, if_, each
a, div, p, span, text, select, input
$show, $hide
bindings, duplex
see} = dc

dc.directives dc.builtinDirectives

{a$} = bindings({a: 1})

describe 'directives', ->

  describe 'model ', ->
    it 'should process model  directive', ->
      comp = text({$model:a$})
      comp.mount()
      comp.node.value = '2'
      comp.node.onchange({type: 'change'})
      expect(a$()).to.equal '2'

    it 'should process event property of component with model directive', ->
      x = 0
      modelValue = duplex(m={}, 'x')
      comp = input({$model:modelValue, onmouseenter: -> x = 1})
      comp.mount()
      comp.node.onmouseenter({type: 'mouseenter'})
      expect(x).to.equal 1

  describe '$show', ->
    it 'should process $show directive', ->
      comp = div({$show:true})
      comp.mount()
      expect(comp.node.style.display).to.equal 'block'

    it 'should process $show directive with non block display', ->
      comp = div({style:{display:"inline"}, $show:true})
      comp.mount()
      expect(comp.node.style.display).to.equal 'inline'

    it 'should process $show directive with false value', ->
      comp = div({$show:false}, div(1))
      comp.mount()
      expect(comp.node.style.display).to.equal 'none'

    it  'should process $show directive with function value', ->
      showing = see true
      comp = div({$show: showing})
      expect(comp.style.display.invalidate).to.be.defined
      comp.mount()
      expect(comp.node.style.display).to.equal 'block', 1
      showing false
      expect(comp.hasActiveStyle).to.equal true
      comp.render()
      expect(comp.node.style.display).to.equal 'none', 2

    it 'should process hide directive', ->
      comp = div({$hide:true}, div(1))
      comp.mount()
      expect(comp.node.style.display).to.equal 'none'
      comp = div({$hide:false}, div(1))
      comp.mount()
      expect(comp.node.style.display).to.equal 'block'

    it 'should process show directive with true or false value', ->
      comp = $show(false)(div(div(1)))
      comp.mount()
      expect(comp.node.style.display).to.equal 'none'
      comp = $show(true)(div(div(1)))
      comp.mount()
      expect(comp.node.style.display).to.equal 'block'

  ndescribe 'select options', ->
    it 'should constructor select with options', ->
      comp = select({$options:[[1,2]]})
      comp.mount()
      expect(comp.node.innerHTML).to.match /<option>1/
      expect(comp.node.innerHTML).to.equal '<option>1</option><option>2</option>'

