{bind,
section, h1, header, form, text, checkbox, div, ul, li, p, a, label, button, footer, strong, span
funcEach, txt
extend} = dc

dc.directives $show: dc.$show

dc.alwaysRender = true

#######################################################################################################################
# store

window.fetch = -> JSON.parse localStorage.getItem('view') || '[]'
window.save = (todos) -> localStorage.setItem('view', JSON.stringify(todos))

#######################################################################################################################
# model
# [ { title: string, completed: boolean } ... ]
window.todos = []

window.todos = fetch()

#######################################################################################################################
# controller

viewStatusHash = null
editingTodo = null
originalTodo = null
reverted = null
saving = false

window.getTodos = ->
  if viewStatusHash=='active'
    todos.filter (todo) -> todo && !todo.completed
  else if viewStatusHash=='completed'
    todos.filter (todo) -> todo && todo.completed
  else todos

remainingCount = -> todos.filter((todo) -> !todo.completed).length
completedCount = -> todos.length - remainingCount()
allChecked = -> !remainingCount()

onEscapeFn = (fn) -> (event) -> if event.keyCode==27 || event.which==27  then fn()

pluralize = (test, item) ->
  if typeof test == 'function'
    txt(->if test()>1 then item+'s' else item)
  else if test>1 then txt(item+'s') else txt(item)

toggleCompleted = (todo) ->
  todo.completed = !todo.completed
  save todos
  view.render()
  dc.clean()

markAll = ->
  if allChecked() then completed = false
  else completed = true

  valid = true
  for todo in todos
    if todo.completed!=completed
      todo.completed = completed
      valid = false

  if !valid
    save(todos)
    view.render()
    dc.clean()

editTodo = (todo) ->
  editingTodo = todo
  originalTodo = extend {}, todo
  view.render()
  dc.clean()

removeTodo = (todo) ->
  index = todos.indexOf todo
  todos.splice index, 1
  save todos
  view.render()
  dc.clean()

revertEdits = (todo) ->
  todos[todos.indexOf(todo)] = originalTodo
  view.render()
  dc.clean()

clearCompletedTodos = ->
  valid = true

  i = todos.length - 1
  while i>=0
    if todos[i].completed
      todos.splice i, 1
      valid = false
    i--

  if !valid
    save todos
    view.render()
    dc.clean()

#######################################################################################################################
# view

text1 = text {
  id: "new-todo"
  placeholder: "What needs to be done?"
  disable: -> saving
  onchange: (event, node) ->
    if !node.value then return
    todos.push title: node.value, completed: false
    save todos
    view.render()
    dc.clean()
  autofocus:true }

todoHeader = header id: "header",
  h1 "todos"
  form id: "todo-form", text1

todoItems = funcEach getTodos, (todo, index) ->

  li className: { completed: (-> todo.completed), editing: -> todo==editingTodo},

    div class: "view",
      checkbox className: "toggle", checked: (-> todo && todo.completed), onchange:(-> toggleCompleted(todo))
      label ondblclick:( -> editTodo(todo) ), (-> todo && todo.title)
      button className: "destroy", onclick:(-> removeTodo(todo))

    form {submit: -> save todos },
      text {
        className: "edit"
        trim: "false"
        value: bind todo, "title"
        onblur: (event, node) -> todo.title = node.value; save(todos); editingTodo = null; view.render(); dc.clean()
        onfocus: -> todo == editingTodo
        onkeyup: onEscapeFn( -> revertEdits(todo) ) }

todoEditArea = section id: "main",

  checkbox {
    id: "toggle-all",
    className: "toggle",
    checked: -> !!allChecked()
    onclick: markAll }

  label "for": "toggle-all",  "Mark all as complete"
  ul id: "todo-list", todoItems

  footer { id: "footer", $show:(-> todos.length) },
    span { id:"todo-count" },  strong(remainingCount),   pluralize(remainingCount, ' item'),  ' left'

    ul id:"filters",
      li a {className: {selected: -> viewStatusHash != 'active' && viewStatusHash != 'completed'}, href: "#/all"}, "All"
      li a {className: {selected: ->  viewStatusHash == 'active'}, href: "#/active"}, "Active"
      li a {className: {selected: -> viewStatusHash == 'completed'}, href: "#/completed"}, "Completed"

    button {id: "clear-completed", onclick: clearCompletedTodos, $show: completedCount },
      txt -> "Clear completed: "+completedCount()

todoFooter = footer id:"info",

  p "Double-click to edit a todo"
  p 'Created by ',
    a href:"http://github.com/taijiweb/domcom",
      'Caoxingming(Tiijizhenren, simeon.chaos@gmail.com)'
  p "Part of ",
    a {href:"http://todomvc.com"},
      " TodoMVC"

view = section id:"todoapp",
  todoHeader
  todoEditArea
  todoFooter

window.updateHash = ->
  locationHash = document.location.hash
  if locationHash.indexOf('/') >= 0
    viewStatusHash = locationHash.split('/')[1] || ''
  else
    viewStatusHash = locationHash

#######################################################################################################################
# run the app

window.runTodoMvc = ->
  updateHash()
  view.mount('#todo-app')

  window.addEventListener 'hashchange',  ->
    updateHash()
    view.render()
    dc.clean()
