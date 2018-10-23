isComponent = require('./isComponent')
Nothing = require('./Nothing')
Text = require('./Text')
{react} = require('lazy-flow')

module.exports = toComponent = (item) ->
  if isComponent(item) then item

  else if typeof item == 'function' then new Text(item)

  else if item instanceof Array
    List = require('./List') # avoid loop require
    new List(for e in item then toComponent(e))

  else if !item? then new Nothing()

  else if item.then && item.catch
    Func = require('./Func') # avoid loop require
    component = new Func react -> component.promiseResult

    item
    .then (value) ->
      component.promiseResult = value
      component.invalideTransform()
    .catch (error) ->
      component.promiseResult = error
      component.invalideTransform()

    component

  else new Text(item)