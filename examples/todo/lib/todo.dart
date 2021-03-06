// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:html' as html;
import 'package:butterfly/butterfly.dart';

Store<Todo> _store;
TodoFactory _todoFactory;

class TodoApp extends StatefulWidget {
  TodoApp() {
    _store = new Store();
    _todoFactory = new TodoFactory();
    _store.add(_todoFactory.create('Foo', false));
    _store.add(_todoFactory.create('Bar', false));
    _store.add(_todoFactory.create('Baz', false));
  }

  @override
  State createState() => new TodoAppState();
}

class TodoAppState extends State<TodoApp> {
  Todo todoEdit = null;

  TodoAppState();

  Node build() {
    var listItems = _store.list.map((Todo todo) {
      return li()([
        div(attrs: {'class': 'view ${todoEdit == todo ? 'hidden' : ''}'})([
          input('checkbox', attrs: {
            'class': 'toggle',
            'checked': attributePresentIf(todo.completed),
          }, eventListeners: {
            EventType.click: (_) {
              completeMe(todo);
            }
          })(),
          label(eventListeners: {
            EventType.dblclick: (_) {
              editTodo(todo);
            }
          })([text(todo.title)]),
          button(attrs: const {
            'class': 'destroy'
          }, eventListeners: {
            EventType.click: (_) {
              deleteMe(todo);
            }
          })(),
        ]),
        div()([
          input('text', attrs: {
            'class': 'edit ${todoEdit == todo ? 'visible': ''}',
            'value': todo.title,
          }, eventListeners: {
            EventType.keyup: (Event event) {
              doneEditing(event, todo);
            }
          })()
        ]),
      ]);
    }).toList();

    return div()([
      section(attrs: const {'id': 'todoapp'})([
        header(attrs: const {'id': 'header'})([
          h1()([text('todos')]),
          input('text', attrs: const {
            'id': 'new-todo',
            'placeholder': 'What needs to be done?',
            'autofocus': '',
          }, eventListeners: {
            EventType.keyup: onKeyEnter((Event event) {
              final value = (event.nativeEvent.target as html.InputElement).value;
              enterTodo(value);
            })
          })(),
        ]),
        section(attrs: const {'id': 'main'})([
          input('checkbox',
              attrs: const {'id': 'toggle-all'},
              eventListeners: {EventType.click: toggleAll})(),
          label(attrs: const {'for': 'toggle-all'})(
              [text('Mark all as complete')]),
          ul(attrs: const {'id': 'todo-list'})(listItems),
        ]),
        footer(attrs: const {'id': 'footer'})([
          span(attrs: const {'id': 'todo-count'})(),
          // Dunno what this does, but it's in the angular2 version
          div(attrs: const {'class': 'hidden'})(),
          ul(attrs: const {'id': 'filters'})([
            li()([
              a(attrs: const {'href': '#/', 'class': 'selected'})(
                  [text('All')]),
            ]),
            li()([
              a(attrs: const {'href': '#/active'})([text('Active')]),
            ]),
            li()([
              a(attrs: const {'href': '#/completed'})([text('Completed')]),
            ]),
          ]),
          button(attrs: const {
            'id': 'clear-completed'
          }, eventListeners: {
            EventType.click: (_) {
              clearCompleted();
            }
          })([text('Clear completed')]),
        ]),
      ]),
      footer(attrs: const {'id': 'info'})([
        p()([text('Double-click to edit a todo')]),
        p()([
          text('Created using '),
          a(attrs: const {'href': 'https://github.com/yjbanov/butterfly'})(
              [text('Butterfly')]),
        ]),
      ]),
    ]);
  }

  void enterTodo(String value) {
    setState(() {
      addTodo(value);
    });
  }

  void editTodo(Todo todo) {
    setState(() {
      this.todoEdit = todo;
    });
  }

  void doneEditing(Event event, Todo todo) {
    final html.KeyEvent keyEvent = event.nativeEvent;
    setState(() {
      int keyCode = keyEvent.keyCode;
      if (keyCode == 13) {
        todo.title = (event.nativeEvent as html.InputElement).value;
        this.todoEdit = null;
      } else if (keyCode == 27) {
        this.todoEdit = null;
      }
    });
  }

  void addTodo(String newTitle) {
    setState(() {
      _store.add(_todoFactory.create(newTitle, false));
    });
  }

  void completeMe(Todo todo) {
    setState(() {
      todo.completed = !todo.completed;
    });
  }

  void deleteMe(Todo todo) {
    setState(() {
      _store.remove(todo);
    });
  }

  void toggleAll(Event event) {
    setState(() {
      var isComplete = (event.nativeEvent as html.CheckboxInputElement).checked;
      _store.list.forEach((Todo todo) {
        todo.completed = isComplete;
      });
    });
  }

  void clearCompleted() {
    setState(() {
      _store.removeWhere((Todo todo) => todo.completed);
    });
  }
}

typedef void ChangeListener();

/// A simple observable model object.
///
/// Extend it to get concrete observable objects.
class Model {
  List<ChangeListener> _listeners;

  void addListener(ChangeListener listener) {
    _listeners ??= <ChangeListener>[];
    _listeners.add(listener);
  }

  void removeListener(ChangeListener listener) {
    if (_listeners == null) return;
    _listeners.removeWhere((l) => l == listener);
  }

  void objectDidChange() {
    if (_listeners == null) return;
    for (var listener in _listeners) {
      listener();
    }
  }
}

abstract class KeyModel extends Model {
  KeyModel(this.key);

  final num key;
}

class Todo extends KeyModel {
  Todo(num key, this._title, this._completed) : super(key);

  String _title;
  String get title => _title;
  set title(String newTitle) {
    if (newTitle != _title) {
      _title = newTitle;
      objectDidChange();
    }
  }

  bool _completed;
  bool get completed => _completed;
  set completed(bool newCompleted) {
    if (newCompleted != _completed) {
      _completed = newCompleted;
      objectDidChange();
    }
  }
}

class TodoFactory {
  int _uid = 0;

  int nextUid() => ++_uid;

  Todo create(String title, bool isCompleted) {
    return new Todo(this.nextUid(), title, isCompleted);
  }
}

class Store<T extends KeyModel> {
  List<T> list = <T>[];

  void add(T record) {
    list.add(record);
  }

  void remove(T record) {
    list.remove(record);
  }

  void removeWhere(bool predicate(T t)) {
    list.removeWhere(predicate);
  }
}
