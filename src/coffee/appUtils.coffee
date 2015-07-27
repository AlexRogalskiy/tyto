Utils = (Utils, App, Backbone, Marionette) ->
  Utils.upgradeMDL = (map) ->
    _.forEach map, (upgrade, idx) ->
      if upgrade.el
        componentHandler.upgradeElement upgrade.el, upgrade.component
  ###
    Syncs model 'ordinal' property to that of the DOM representation.

    NOTE :: This shouldn't be doing a loop through the collection using
    model.save. With a proper backend this could be avoided but on
    localStorage it will work with no real performance hit.
  ###
  Utils.reorder = (entity, list, attr) ->
    collection = entity.collection
    _.forEach list, (item, idx) ->
      id    = item.getAttribute attr
      model = collection.get id
      if model
        model.save
          ordinal: idx + 1

  Utils.processQueryString = (params) ->
    qS = {}
    pushToQs = (set) ->
      set = set.split '='
      qS[set[0]] = set[1]
    _.map params.split('&'), pushToQs
    qS

  Utils.bloom = (el, color, url) ->
    $boomer = Tyto.BoardView.ui.boomer
    boomer  = $boomer[0]
    coord   = el.getBoundingClientRect()
    boomer.style.left = coord.left + (coord.width / 2) + 'px'
    boomer.style.top  = coord.top + (coord.height / 2) + 'px'
    boomer.className = 'tyto-board__boomer ' + 'bg--' + color
    boomer.classList.add 'is--booming'
    Tyto.RootView.el.classList.add 'is--showing-boom'
    goToEdit = ->
      $boomer.off Tyto.ANIMATION_EVENT, goToEdit
      Tyto.navigate url, true
    $boomer.on Tyto.ANIMATION_EVENT, goToEdit

  Utils.load = (data, importing, wipe) ->
    boards  = []
    cols    = []
    tasks   = []
    altered = {}

    if importing
      delete data.tyto
      delete data['tyto--board']
      delete data['tyto--column']
      delete data['tyto--task']

    if wipe
      _.forOwn window.localStorageJ, (val, key) ->
        if key.indexOf('tyto') isnt -1
          window.localStorage.removeItem key

    _.forOwn data, (val, key) ->
      if wipe
        window.localStorage.setItem key, val
      if key.indexOf('tyto--board-') isnt -1
        if importing
          entity = JSON.parse val
          if Tyto.Boards.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.Boards.create(entity).id
        else
          boards.push JSON.parse val
      if key.indexOf('tyto--column-') isnt -1
        if importing
          entity = JSON.parse val
          if altered[entity.boardId]
            entity.boardId = altered[entity.boardId]
          if Tyto.Columns.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.Columns.create(entity).id
        else
          cols.push JSON.parse val
      if key.indexOf('tyto--task-') isnt -1
        if importing
          entity = JSON.parse val
          if altered[entity.boardId]
            entity.boardId = altered[entity.boardId]
          if altered[entity.columnId]
            entity.columnId = altered[entity.columnId]
          if Tyto.Tasks.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.Tasks.create(entity).id
        else
          tasks.push JSON.parse val

    if !importing
      Tyto.Boards.reset boards
      Tyto.Columns.reset cols
      Tyto.Tasks.reset tasks


  ###
    The EMAIL_TEMPLATE is not a particularly nice thing to look at. In order to
    maintain formatting and not introduce much unwanted whitespace I've resorted
    to using a large string with no indentation.

    I did try implementing this part through the templateStore but with mixed results. May return to look at this at a later date.
  ###
  Utils.EMAIL_TEMPLATE = '''
    <div>Status for: <%= board.title %>\n\n<% if (columns.length > 0 && tasks.length > 0) { %><% _.forEach(columns, function(column) { %><%= column.attributes.title %>\n&#8212;&#8212;&#8212;&#8212;&#8212;&#8212;&#8212;&#8212;&#8212;&#8212;\n\n<% _.forEach(tasks, function(task) { %><% if (task.attributes.columnId === column.attributes.id) { %>&#8226; <%= task.attributes.title %>; <%= task.attributes.description %>\n<% } %><% });%>\n<% }); %><% } else { %>Seems we are way ahead, so treat yourself and go grab a coffee! :)<% } %></div>
  '''

  Utils.getEmailContent = (board) ->
    mailString = 'mailto:'
    recipient  = 'someone@somewhere.com'
    subject    = 'Status for ' + Tyto.ActiveBoard.get('title') + ' as of ' + new Date().toString()
    templateFn = _.template Tyto.Utils.EMAIL_TEMPLATE
    content = templateFn
      board  : board.attributes
      columns: Tyto.Columns.where({boardId: board.id})
      tasks  : Tyto.Tasks.where({boardId: board.id})
    content = _.escape $(content).html()
    content = encodeURIComponent content

    mailString + recipient + '?subject=' + encodeURIComponent(subject.trim()) + '&body=' + content

module.exports = Utils
