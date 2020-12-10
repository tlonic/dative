define [
  'backbone'
  # 'FieldDB'
  './../routes/router'
  './base'
  './resource'
  './mainmenu'
  './notifier'
  './login-dialog'
  './register-dialog'
  './alert-dialog'
  './tasks-dialog'
  './help-dialog'
  './resource-displayer-dialog'
  './resources-displayer-dialog'
  './exporter-dialog'
  './home'

  './application-settings'
  './collections'
  './corpora'
  './elicitation-methods'
  './files'
  './forms'
  './keyboards'
  './language-models'
  './languages'
  './morphological-parsers'
  './morphologies'
  './orthographies'
  './pages'
  './phonologies'
  './searches'
  './sources'
  './speakers'
  './subcorpora'
  './syntactic-categories'
  './tags'
  './users'

  './event-based-keyboard'
  './collection'
  './elicitation-method'
  './file'
  './form'
  './keyboard'
  './language-model'
  './language'
  './morphological-parser'
  './morphology'
  './orthography'
  './page'
  './phonology'
  './search'
  './source'
  './speaker'
  './subcorpus'
  './syntactic-category'
  './tag'
  './user-old-circular'

  './../models/application-settings'
  './../models/collection'
  './../models/elicitation-method'
  './../models/file'
  './../models/form'
  './../models/keyboard'
  './../models/language-model'
  './../models/language'
  './../models/morphological-parser'
  './../models/morphology'
  './../models/old-application-settings'
  './../models/orthography'
  './../models/page'
  './../models/phonology'
  './../models/search'
  './../models/server'
  './../models/source'
  './../models/speaker'
  './../models/subcorpus'
  './../models/syntactic-category'
  './../models/tag'
  './../models/user-old'

  './../collections/collections'
  './../collections/elicitation-methods'
  './../collections/files'
  './../collections/forms'
  './../collections/keyboards'
  './../collections/language-models'
  './../collections/languages'
  './../collections/morphological-parsers'
  './../collections/morphologies'
  './../collections/orthographies'
  './../collections/old-application-settings'
  './../collections/pages'
  './../collections/phonologies'
  './../collections/searches'
  './../collections/servers'
  './../collections/sources'
  './../collections/speakers'
  './../collections/subcorpora'
  './../collections/syntactic-categories'
  './../collections/tags'
  './../collections/users'

  './../utils/globals'
  './../templates/app'
], (Backbone, Workspace, BaseView, ResourceView, MainMenuView,
  NotifierView, LoginDialogView, RegisterDialogView, AlertDialogView,
  TasksDialogView, HelpDialogView, ResourceDisplayerDialogView,
  ResourcesDisplayerDialogView, ExporterDialogView, HomePageView,

  ApplicationSettingsView, CollectionsView, CorporaView,
  ElicitationMethodsView, FilesView, FormsView, KeyboardsView,
  LanguageModelsView, LanguagesView, MorphologicalParsersView,
  MorphologiesView, OrthographiesView, PagesView, PhonologiesView,
  SearchesView, SourcesView, SpeakersView, SubcorporaView,
  SyntacticCategoriesView, TagsView, UsersView,

  EventBasedKeyboardView, CollectionView, ElicitationMethodView, FileView,
  FormView, KeyboardView, LanguageModelView, LanguageView,
  MorphologicalParserView, MorphologyView, OrthographyView, PageView,
  PhonologyView, SearchView, SourceView, SpeakerView, SubcorpusView,
  SyntacticCategoryView, TagView, UserView,

  ApplicationSettingsModel, CollectionModel, ElicitationMethodModel, FileModel,
  FormModel, KeyboardModel, LanguageModelModel, LanguageModel,
  MorphologicalParserModel, MorphologyModel, OLDApplicationSettingsModel,
  OrthographyModel, PageModel, PhonologyModel, SearchModel, ServerModel,
  SourceModel, SpeakerModel, SubcorpusModel, SyntacticCategoryModel, TagModel,
  UserModel,

  CollectionsCollection, ElicitationMethodsCollection, FilesCollection,
  FormsCollection, KeyboardsCollection, LanguageModelsCollection,
  LanguagesCollection, MorphologicalParsersCollection, MorphologiesCollection,
  OrthographiesCollection, OLDApplicationSettingsCollection, PagesCollection,
  PhonologiesCollection, SearchesCollection, ServersCollection,
  SourcesCollection, SpeakersCollection, SubcorporaCollection,
  SyntacticCategoriesCollection, TagsCollection, UsersCollection,

  globals, appTemplate) ->


  # App View
  # --------
  #
  # This is the spine of the application. Only one AppView object is created
  # and it controls the creation and rendering of all of the subviews that
  # control the content in the body of the page.

  class AppView extends BaseView

    template: appTemplate
    el: '#dative-client-app'

    close: ->
      @closeVisibleView()
      super

    # A `FieldView` has just told us that one of its <textarea>s was focused;
    # `index` tells us which one.
    setLastFocusedField: (fieldView, index=0) ->
      @lastFocusedField = fieldView
      @lastFocusedFieldIndex = index

    # An event-based keyboard is telling us to alert the last focused field view
    # that it should insert `value` at its current cursor position.
    keyboardValueReceived: (value) ->
      if @lastFocusedField
        @lastFocusedField.trigger 'keyboardValue', value, @lastFocusedFieldIndex

    initialize: (options) ->
      @lastFocusedField = null
      @lastFocusedFieldIndex = 0
      @setHash()
      @preventParentScroll()
      @getApplicationSettings options
      @activeKeyboard = @getSystemWideKeyboard()
      @fetchServers()

    getSystemWideKeyboard: ->
      systemWideKeyboard = super globals
      if systemWideKeyboard
        new KeyboardModel systemWideKeyboard
      else
        null

    # If the user navigates to a particular part of the app using the hash
    # string, then we want to remember that hash and navigate to it.
    setHash: ->
      hash = window.location.hash
      if hash
        @hash = @utils.hyphen2camel hash[1...]
      else
        @hash = null

    # Continue initialization after fetching servers.json
    initializeContinue: ->
      globals.applicationSettings = @applicationSettings
      # @overrideFieldDBNotificationHooks()
      @initializePersistentSubviews()
      @resourceModel = null # this and the next attribute are for displaying a single resource in the main page.
      @resourcesCollection = null
      @router = new Workspace
        resources: @myResources
        mainMenuView: @mainMenuView
      @oldApplicationSettingsCollection = new OLDApplicationSettingsCollection()
      @listenToEvents()
      @render()
      @setTheme()
      Backbone.history.start()
      @preventNavigationState = false
      @navigate()

    # Only navigate home if there is no hash string in the URL. This seems to
    # be sufficient to ensure that refreshing on, say the forms browse page
    # ('#forms') will result in that page being re-rendered.
    navigate: ->
      if not @hash
        @showHomePageView()

    # Calling this method will cause all scrollable <div>s with the class
    # .Scrollable, to prevent (x and y axis) scroll propagation to parent divs.
    # This is good because (with a trackpad, at least), there is often an
    # annoying "over-scrolling" effect, which, in the x-axis can trigger the
    # browser's forward or back button events, which is highly undesirable.
    # See http://stackoverflow.com/a/16324762/992730
    preventParentScroll: ->
      $(document).on('DOMMouseScroll mousewheel', '.Scrollable', (ev) ->
        $this = $ this
        scrollTop = @scrollTop
        scrollLeft = @scrollLeft
        scrollHeight = @scrollHeight
        scrollWidth = @scrollWidth
        height = $this.height()
        width = $this.width()
        if ev.type is 'DOMMouseScroll'
          delta = ev.originalEvent.detail * -40
        else
          delta = ev.originalEvent.wheelDelta
        up = delta > 0
        prevent = ->
          ev.stopPropagation()
          ev.preventDefault()
          ev.returnValue = false
          false
        result = true
        deltaX = ev.originalEvent.wheelDeltaX
        if (not up) and -delta > scrollHeight - height - scrollTop
          $this.scrollTop scrollHeight
          if deltaX then $this.scrollLeft(@scrollLeft - deltaX)
          result = prevent()
        else if up and delta > scrollTop
          $this.scrollTop(0)
          if deltaX then $this.scrollLeft(@scrollLeft - deltaX)
          result = prevent()
        if deltaX
          left = deltaX > 0
          if (not left) and -deltaX > scrollWidth - width - scrollLeft
            $this.scrollLeft scrollWidth
            $this.scrollTop(@scrollTop - delta)
            result = prevent()
          else if left and deltaX > scrollLeft
            $this.scrollLeft(0)
            $this.scrollTop(@scrollTop - delta)
            result = prevent()
        result
      )

    events:
      'click': 'bodyClicked'
      'keydown': 'broadcastKeydown'
      'keyup': 'broadcastKeyup'

    broadcastKeydown: (event) ->
      if @activeKeyboard
        @activeKeyboard.trigger 'systemWideKeydown', event

    broadcastKeyup: ->
      if @activeKeyboard
        @activeKeyboard.trigger 'systemWideKeyup', event

    render: ->
      if window.location.hostname is ['localhost', '127.0.0.1']
        setTimeout ->
          console.clear()
        , 2000
      @loggedIn()
      @$el.html @template()
      @renderPersistentSubviews()
      @matchWindowDimensions()
      @

    # Another view has asked us to prevent navigation, i.e., the changing of
    # the currently displayed view in the main page. The `msg` is the message
    # that we display in the "Prevent Navigation" confirm dialog.
    setPreventNavigation: (msg) ->
      @preventNavigationState = true
      @preventNavigationMsg = msg

    # Unset our instance vars related to preventing navigation.
    unsetPreventNavigation: ->
      @preventNavigationState = false
      @preventNavigationMsg = null

    # Display the confirm dialog that asks the user whether they really want to
    # navigate away from the current page.
    displayPreventNavigationAlert: ->
      if @preventNavigationMsg
        msg = @preventNavigationMsg
      else
        msg = 'Do you really want to navigate away from the current page? Click
          “Ok” to continue with navigation. Click “Cancel” to stay on
          the current page.'
      options =
        confirm: false
        text: msg
      Backbone.trigger 'openAlertDialog', options

    listenToEvents: ->
      @listenTo Backbone, 'setPreventNavigation', @setPreventNavigation
      @listenTo Backbone, 'unsetPreventNavigation', @unsetPreventNavigation
      @listenTo Backbone, 'preventNavigation', @preventNavigation
      @listenTo Backbone, 'mergeNewServers', @mergeNewServers
      @listenTo Backbone, 'lastFocusedField', @setLastFocusedField
      @listenTo Backbone, 'keyboardValue', @keyboardValueReceived

      @listenTo @mainMenuView, 'request:home', @showHomePageView
      @listenTo @mainMenuView, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @mainMenuView, 'request:toggleHelpDialogBox', @toggleHelpDialog
      @listenTo @mainMenuView, 'request:toggleTasksDialog', @toggleTasksDialog
      @listenTo @mainMenuView, 'request:openRegisterDialogBox',
        @toggleRegisterDialog

      @listenTo @router, 'route:home', @showHomePageView
      @listenTo @router, 'route:openLoginDialogBox', @toggleLoginDialog
      @listenTo @router, 'route:openRegisterDialogBox', @toggleRegisterDialog

      @listenTo @loginDialog, 'request:openRegisterDialogBox',
        @toggleRegisterDialog
      @listenTo Backbone, 'loginSuggest', @openLoginDialogWithDefaults
      @listenTo Backbone, 'authenticateSuccess', @authenticateSuccess
      @listenTo Backbone, 'authenticate:mustconfirmidentity',
        @authenticateConfirmIdentity
      @listenTo Backbone, 'logoutSuccess', @logoutSuccess
      # @listenTo Backbone, 'useFieldDBCorpus', @useFieldDBCorpus
      @listenTo Backbone, 'applicationSettings:changeTheme', @changeTheme
      @listenTo Backbone, 'showResourceInDialog', @showResourceInDialog
      @listenTo Backbone, 'showResourceModelInDialog',
        @showResourceModelInDialog
      @listenTo Backbone, 'showEventBasedKeyboardInDialog',
        @showEventBasedKeyboardInDialog
      @listenTo Backbone, 'closeAllResourceDisplayerDialogs',
        @closeAllResourceDisplayerDialogs
      @listenTo Backbone, 'openExporterDialog', @openExporterDialog
      @listenTo Backbone, 'routerNavigateRequest', @routerNavigateRequest
      @listenToResources()
      @listenToOLDApplicationSettingsCollection()
      @listenTo Backbone, 'homePageChanged', @homePageChanged

    # Note the strange spellings of the events triggered here; just go along
    # with it ...
    listenToOLDApplicationSettingsCollection: ->
      @listenTo Backbone, 'fetchOldApplicationSettingsesEnd',
        @fetchOLDApplicationSettingsEnd
      @listenTo Backbone, 'fetchOldApplicationSettingsesStart',
        @fetchOLDApplicationSettingsStart
      @listenTo Backbone, 'fetchOldApplicationSettingsesSuccess',
        @fetchOLDApplicationSettingsSuccess
      @listenTo Backbone, 'fetchOldApplicationSettingsesFail',
        @fetchOLDApplicationSettingsFail

    fetchOLDApplicationSettingsEnd: ->

    fetchOLDApplicationSettingsStart: ->

    fetchOLDApplicationSettingsSuccess: ->
      if @oldApplicationSettingsCollection.length > 0
        globals.oldApplicationSettings = @oldApplicationSettingsCollection
          .at(@oldApplicationSettingsCollection.length - 1)
      else
        console.log 'This OLD has no app settings!?'
        globals.oldApplicationSettings = null

    fetchOLDApplicationSettingsFail: ->
      console.log 'FAILED to get OLD app settings'
      globals.oldApplicationSettings = null
      # Failing to fetch the application settings of an OLD is an indication
      # from the server that we are not logged in.
      @applicationSettings.set 'loggedIn', false
      @applicationSettings.save()

    routerNavigateRequest: (route) -> @router.navigate route

    # Listen for resource-related events. The resources and relevant events
    # are configured by the `@myResources` object.
    # TODO/QUESTION: why not just listen on the resources subclass instead of
    # on Backbone with all of this complex naming stuff?
    listenToResources: ->
      for resource, config of @myResources
        do =>
          resourceName = resource
          resourcePlural = @utils.pluralize resourceName
          resourceCapitalized = @utils.capitalize resourceName
          resourcePluralCapitalized = @utils.capitalize resourcePlural
          @listenTo Backbone, "destroy#{resourceCapitalized}Success",
            (resourceModel) => @destroyResourceSuccess resourceModel
          @listenTo Backbone, "#{resourcePlural}View:showAllLabels",
            => @changeDisplaySetting resourcePlural, 'dataLabelsVisible', true
          @listenTo Backbone, "#{resourcePlural}View:hideAllLabels",
            =>
              @changeDisplaySetting resourcePlural, 'dataLabelsVisible', false
          @listenTo Backbone,
            "#{resourcePlural}View:expandAll#{resourcePluralCapitalized}",
            =>
              @changeDisplaySetting resourcePlural,
                "all#{resourcePluralCapitalized}Expanded", true
          @listenTo Backbone,
            "#{resourcePlural}View:collapseAll#{resourcePluralCapitalized}",
            =>
              @changeDisplaySetting resourcePlural,
                "all#{resourcePluralCapitalized}Expanded", false
          @listenTo Backbone, "#{resourcePlural}View:itemsPerPageChange",
            (newItemsPerPage) =>
              @changeDisplaySetting resourcePlural, 'itemsPerPage',
                newItemsPerPage
          @listenTo @mainMenuView, "request:#{resourcePlural}Browse",
            (options={}) => @showResourcesView resourceName, options
          @listenTo @mainMenuView, "meta:request:#{resourcePlural}Browse",
            (options={}) => @showResourcesViewInDialog resourceName, options
          @listenTo @mainMenuView, "request:#{resourceName}Add",
            => @showNewResourceView resourceName
          @listenTo @mainMenuView, "request:#{resourcePlural}Import",
            => @showImportView resourceName
          if config.params?.searchable is true
            @listenTo Backbone, "request:#{resourcePlural}BrowseSearchResults",
              (options={}) => @showResourcesView resourceName, options
          if config.params?.corpusElement is true
            @listenTo Backbone, "request:#{resourcePlural}BrowseCorpus",
              (options={}) => @showResourcesView resourceName, options
          @listenTo Backbone, "request:#{resourceCapitalized}View",
            (id) => @showResourceView(resourceName, id)

    initializePersistentSubviews: ->
      @mainMenuView = new MainMenuView model: @applicationSettings
      @loginDialog = new LoginDialogView model: @applicationSettings
      @registerDialog = new RegisterDialogView model: @applicationSettings
      @alertDialog = new AlertDialogView model: @applicationSettings
      @tasksDialog = new TasksDialogView model: @applicationSettings
      @helpDialog = new HelpDialogView()
      @notifier = new NotifierView(@myResources)
      @exporterDialog = new ExporterDialogView()
      @getResourceDisplayerDialogs()
      @resourcesDisplayerDialog = new ResourcesDisplayerDialogView()

    renderPersistentSubviews: ->
      @mainMenuView.setElement(@$('#mainmenu')).render()
      @loginDialog.setElement(@$('#login-dialog-container')).render()
      @registerDialog.setElement(@$('#register-dialog-container')).render()
      @alertDialog.setElement(@$('#alert-dialog-container')).render()
      @tasksDialog.setElement(@$('#tasks-dialog-container')).render()
      @helpDialog.setElement(@$('#help-dialog-container'))
      @renderResourceDisplayerDialogs()
      @notifier.setElement(@$('#notifier-container')).render()
      @exporterDialog.setElement(@$('#exporter-dialog-container')).render()
      @resourcesDisplayerDialog.setElement(
        @$('#resources-dialog-container')).render()

      @rendered @mainMenuView
      @rendered @loginDialog
      @rendered @registerDialog
      @rendered @alertDialog
      @rendered @tasksDialog
      @rendered @notifier
      @rendered @exporterDialog
      @rendered @resourcesDisplayerDialog

    renderHelpDialog: ->
      @helpDialog.render()
      @rendered @helpDialog

    bodyClicked: ->
      Backbone.trigger 'bodyClicked' # Mainmenu superclick listens for this

    useFieldDBCorpus: (corpusId) ->
      currentlyActiveFieldDBCorpus = @activeFieldDBCorpus
      fieldDBCorporaCollection = @corporaView?.collection
      @activeFieldDBCorpus = fieldDBCorporaCollection?.findWhere
        pouchname: corpusId
      @applicationSettings.save
        'activeFieldDBCorpus': corpusId
        'activeFieldDBCorpusTitle': @activeFieldDBCorpus.get 'title'
        'activeFieldDBCorpusModel': @activeFieldDBCorpus # TODO: FIX THIS ABERRATION!
      globals.activeFieldDBCorpus = @activeFieldDBCorpus
      if currentlyActiveFieldDBCorpus is @activeFieldDBCorpus
        @showFormsView fieldDBCorpusHasChanged: false
      else
        # @mainMenuView.activeFieldDBCorpusChanged @activeFieldDBCorpus.get('title')
        @showFormsView fieldDBCorpusHasChanged: true

    logoutSuccess: ->
      @closeVisibleView()
      @corporaView = null
      @usersView = null # TODO: all of these collection views should be DRY-ly emptied upon logout ...
      @showHomePageView true

    activeServerType: ->
      try
        @applicationSettings.get('activeServer').get 'type'
      catch
        null

    authenticateSuccess: ->
      activeServerType = @activeServerType()
      switch activeServerType
        when 'FieldDB'
          if @applicationSettings.get('fieldDBApplication') isnt
          FieldDB.FieldDBObject.application
            @applicationSettings.set 'fieldDBApplication',
              FieldDB.FieldDBObject.application
          @showCorporaView()
        when 'OLD'
          @oldApplicationSettingsCollection.fetchResources()
          @showFormsView()
        else console.log 'Error: you logged in to a non-FieldDB/non-OLD server
          (?).'

    authenticateConfirmIdentity: (message) =>
      message = message or 'We need to make sure this is you. Confirm your
        password to continue.'
      if not @originalMessage then @originalMessage = message
      @displayConfirmIdentityDialog(
          message
        ,
          (loginDetails) =>
            console.log 'no problem.. can keep working'
            fieldDBApplication = @applicationSettings.get('fieldDBApplication')
            @set
              username: fieldDBApplication.authentication.user.username,
              loggedInUser: fieldDBApplication.authentication.user
            @save()
            delete @originalMessage
        ,
          (loginDetails) =>
            if @confirmIdentityErrorCount > 3
              console.log ' In this case of confirming identity, the user MUST
                authenticate. If they cant remember their password, after 4
                attempts, log them out.'
              delete @originalMessage
              Backbone.trigger 'authenticate:logout'
            console.log 'Asking again'
            @confirmIdentityErrorCount = @confirmIdentityErrorCount or 0
            @confirmIdentityErrorCount += 1
            @authenticateConfirmIdentity "#{@originalMessage}
              #{loginDetails.userFriendlyErrors.join ' '}"
      )

    # Set `@applicationSettings`
    getApplicationSettings: (options) ->
      # Allowing an app settings model in the options facilitates testing.
      if options?.applicationSettings
        @applicationSettings = options.applicationSettings
      else
        @applicationSettings = new ApplicationSettingsModel()

    # We have fetched the default servers array from the server hosting this
    # Dative.
    addDefaultServers: (serversArray) ->

      # If the user has manually modified their locally stored list of servers,
      # we won't overwrite that with what Dative gives them in servers.json.
      # However, we will prompt them to see if they want to merge the new stuff
      # from Dative into what they have.
      if @applicationSettings.get('serversModified')
        @promptServersMerge serversArray
      else
        serverModelsArray = []
        for s in serversArray
          s.id = @guid()
          serverModelsArray.push(new ServerModel(s))
        serversCollection = new ServersCollection(serverModelsArray)
        @applicationSettings.set 'servers', serversCollection
        try
          activeServer = @applicationSettings.get('activeServer').get('name')
          newActiveServer = serversCollection.findWhere name: activeServer
          @applicationSettings.set 'activeServer', newActiveServer
        catch e
          activeServer = serversCollection.at 0
          @applicationSettings.set 'activeServer', activeServer
        @applicationSettings.save()
      @initializeContinue()

    # Display a confirm dialog that describes the servers that Dative knows
    # about but which they don't and ask the user whether they want to add
    # these servers to their list of servers.
    promptServersMerge: (serversArray) ->
      # `lastSeen` is the array of servers that we were prompted to merge last
      # time. We don't want to keep pestering the user to merge the same array
      # of servers.
      lastSeen = @applicationSettings.get 'lastSeenServersFromDative'
      if not _.isEqual(serversArray, lastSeen)
        @applicationSettings.set 'lastSeenServersFromDative', serversArray
        @applicationSettings.save()
        existingServerNames = []
        @applicationSettings.get('servers').each (m) ->
          existingServerNames.push m.get('name')
        newServers = (s for s in serversArray when s['name'] not in
          existingServerNames)
        if newServers.length > 0
          newServerNames = "“#{(s['name'] for s in newServers).join '”, “'}”"
          if newServers.length == 1
            msg = "Dative knows about the OLD server #{newServerNames} but you
              don't. Would you like to add the server #{newServerNames} to your
              list of known servers?"
          else
            msg = "Dative knows about the following servers that you don't:
              #{newServerNames}. Would you like to add these servers to your
              list of known servers?"
          options =
            text: msg
            confirm: true
            confirmEvent: "mergeNewServers"
            confirmArgument: newServers
          setTimeout (-> Backbone.trigger 'openAlertDialog', options), 1000

    # The user has confirmed that they want to merge the new servers in
    # `newServers` into their current client-side list of servers.
    mergeNewServers: (newServers) ->
      serversCollection = @applicationSettings.get 'servers'
      for s in newServers
        s.id = @guid()
        serversCollection.add(new ServerModel(s))
      @applicationSettings.save()

    # Fetch servers.json. This is a JSON object that contains an array of
    # server objects. This allows the default list of (OLD/FieldDB) servers
    # that this Dative knows about to be specified at runtime.
    fetchServers: ->
      url = 'servers.json'
      $.ajax
        url: url
        type: 'GET'
        dataType: 'json'
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "Ajax request for #{url} threw an error:
            #{errorThrown}"
          @initializeContinue()
        success: (serversArray, textStatus, jqXHR) =>
          @addDefaultServers serversArray

    # Size the #appview div relative to the window size
    matchWindowDimensions: ->
      @$('#appview').css height: $(window).height() - 50
      $(window).resize =>
        @$('#appview').css height: $(window).height() - 50

    renderVisibleView: (taskId=null) ->
      try
        @__renderVisibleView__ taskId
      catch
        try
          @__renderVisibleView__ taskId
        catch
          try
            @__renderVisibleView__ taskId

    __renderVisibleView__: (taskId=null) ->
      if (@visibleView instanceof ResourceView)
        @$('#appview')
          .css 'overflow-y', 'scroll'
          .html @visibleView.render().el
      else
        $appView = @$ '#appview'
        $appView.css 'overflow-y', 'initial'
        @visibleView.setElement $appView
        @visibleView.render taskId
      @rendered @visibleView

    closeVisibleView: -> if @visibleView then @closeView @visibleView

    closeVisibleViewInDialog: ->
      if @visibleViewInDialog then @closeView @visibleViewInDialog

    # Check if our application settings still thinks we're logged in.
    loggedIn: ->
      @loggedInFieldDB()
      loggedIn = @applicationSettings.get 'loggedIn'
      if loggedIn then @getOLDApplicationSettings()
      loggedIn

    # Check if FieldDB thinks we're logged in to a FieldDB. If it does, set
    # `@loggedIn` to `true`, else `false`.
    loggedInFieldDB: ->
      if @applicationSettings.get('fieldDBApplication')
        fieldDBApp = @applicationSettings.get 'fieldDBApplication'
        if fieldDBApp.authentication and
        fieldDBApp.authentication.user and
        fieldDBApp.authentication.user.authenticated
          @applicationSettings.set 'loggedIn', true
          @applicationSettings.set 'loggedInUserRoles',
            fieldDBApp.authentication.user.roles
        else
          @applicationSettings.set 'loggedIn', false

    getOLDApplicationSettings: ->
      if @activeServerType() is 'OLD'
        @oldApplicationSettingsCollection.fetchResources()

    showHomePageView: (logout=false) ->
      if @preventNavigationState then @displayPreventNavigationAlert(); return
      if (not logout) and @homePageView and (@visibleView is @homePageView)
        return
      @router.navigate 'home'
      @closeVisibleView()
      if not @homePageView then @homePageView = new HomePageView()
      serversideHomepage = @applicationSettings.get 'homepage'
      if serversideHomepage
        @homePageView.setHTML(serversideHomepage.html,
          serversideHomepage.heading)
      else
        @homePageView.setHTML null, null
      @visibleView = @homePageView
      @renderVisibleView()

    homePageChanged: ->
      if @homePageView
        @homePageView.contentChanged()

    ############################################################################
    # Show resources view machinery
    ############################################################################

    # Render (and perhaps instantiate) a view over a collection of resources.
    # This method works in conjunction with the metadata in the `@myResources`
    # object; CRUCIALLY, only resources with an attribute in that object can be
    # shown using this method. The simplest case is to call this method with
    # the singular camelCase name of a resource as its first argument; e.g.,
    # `@showResourcesView 'elicitationMethod'`.
    showResourcesView: (resourceName, options={}) ->
      if @preventNavigationState then @displayPreventNavigationAlert(); return
      o = @showResourcesViewSetDefaultOptions resourceName, options
      names = @getResourceNames resourceName
      myViewAttr = "#{names.plural}View"
      if o.authenticationRequired and not @loggedIn() then return
      if o.searchable and o.search
        @closeVisibleView()
        @visibleView = null
      if @[myViewAttr] and @visibleView is @[myViewAttr] then return
      @router.navigate names.hypPlur
      taskId = @guid()
      Backbone.trigger 'longTask:register', "Opening #{names.regPlur} view",
        taskId
      @closeVisibleView()
      if @[myViewAttr]
        if @fieldDBCorpusHasChanged(myViewAttr, o)
          @closeView @[myViewAttr]
          @[myViewAttr] = @instantiateResourcesView resourceName, o
      else
        @[myViewAttr] = @instantiateResourcesView resourceName, o
      @visibleView = @[myViewAttr]
      @showNewResourceViewOption o
      @showImportInterfaceOption o
      @searchableOption o
      @corpusElementOption o
      @renderVisibleView taskId

    # Render (and perhaps instantiate) a view over a collection of resources *in
    # a modal dialog.* Compare to `showResourcesView`.
    showResourcesViewInDialog: (resourceName, options={}) ->
      o = @showResourcesViewSetDefaultOptions resourceName, options
      names = @getResourceNames resourceName
      myViewAttr = "#{names.plural}ViewInDialog"
      if o.authenticationRequired and not @loggedIn() then return
      if o.searchable and o.search
        @closeVisibleViewInDialog()
        @visibleViewInDialog = null
      if @[myViewAttr] and @visibleViewInDialog is @[myViewAttr]
        if @resourcesDisplayerDialog.isOpen()
          return
      @closeVisibleViewInDialog()
      if @[myViewAttr]
        if @fieldDBCorpusHasChanged(myViewAttr, o)
          @closeView @[myViewAttr]
          @[myViewAttr] = @instantiateResourcesView resourceName, o
      else
        @[myViewAttr] = @instantiateResourcesView resourceName, o
      @visibleViewInDialog = @[myViewAttr]
      @resourcesDisplayerDialog.showResourcesView @visibleViewInDialog

    # Show the resource of type `resourceName` with id `resourceId` in the main
    # page of the application. This is what happens when you navigate to, e.g.,
    # /#form/123. This method also handles navigation to collections via their
    # URL (i.e., path) values.
    showResourceView: (resourceName, resourceId, options={}) ->
      if @preventNavigationState then @displayPreventNavigationAlert(); return
      o = @showResourceViewSetDefaultOptions resourceName, options
      names = @getResourceNames resourceName
      myViewAttr = "#{resourceName}View"
      if o.authenticationRequired and not @loggedIn() then return
      if @[myViewAttr] and @visibleView is @[myViewAttr] then return
      @router.navigate "#{names.hyphen}/#{resourceId}"
      @closeVisibleView()
      @resourcesCollection =
        new @myResources[resourceName].resourcesCollectionClass()
      if @resourceModel then @stopListening @resourceModel
      @resourceModel = new @myResources[resourceName].resourceModelClass(
        {}, {collection: @resourcesCollection})

      # Fetch a resource by its id value.
      if _.isNumber(resourceId) or /^\d+$/.test(resourceId.trim())
        # We have to listen and fetch here, which is different from
        # `ResourcesView` sub-classes, which fetch their collections post-render.
        @listenToOnce @resourceModel, "fetch#{names.capitalized}Fail",
          (error, resourceModel) => @fetchResourceFail resourceName, resourceId
        @listenToOnce @resourceModel, "fetch#{names.capitalized}Success",
          (resourceObject) =>
            @fetchResourceSuccess resourceName, myViewAttr, resourceObject
        @resourceModel.fetchResource resourceId
      # Fetch a collection by its url value.
      else if resourceName is 'collection'
        @listenToOnce @resourceModel, "searchFail",
          (error) => @fetchResourceFail resourceName, resourceId, 'url'
        @listenToOnce @resourceModel, "searchSuccess",
          (responseJSON) =>
            if @utils.type(responseJSON) is 'array' and responseJSON.length > 0
              @fetchResourceSuccess resourceName, myViewAttr, responseJSON[0]
            else
              @fetchResourceFail resourceName, resourceId, 'url'
        search =
          filter: ["Collection", "url", "=", resourceId]
          order_by: ["Form", "id", "desc" ]
        @resourceModel.search search, null, false
      else
        @displayErrorPage "Sorry, there is no #{resourceName} with id
          #{resourceId}"

    # We failed to fetch the resource model data from the server.
    fetchResourceFail: (resourceName, resourceId, attr='id') ->
      @stopListening @resourceModel
      @displayErrorPage "Sorry, there is no #{resourceName} with #{attr}
        #{resourceId}"

    # We succeeded in fetching the resource model data from the server,
    # so we render a `ResourceView` subclass for it.
    fetchResourceSuccess: (resourceName, myViewAttr, resourceObject) ->
      @stopListening @resourceModel
      @resourceModel.set resourceObject
      @[myViewAttr] = new @myResources[resourceName].resourceViewClass
        model: @resourceModel
        dataLabelsVisible: true
        expanded: true
      @visibleView = @[myViewAttr]
      @renderVisibleView()

    displayErrorPage: (msg=null) ->
      @router.navigate "error"
      @closeVisibleView()
      if not msg then msg = 'Sorry, an error occurred.'
      @$('#appview').html(@getErrorPageHTML('Error', msg))
      @$('.dative-error-page')
        .css "border-color", @constructor.jQueryUIColors().defBo

    getErrorPageHTML: (header, content) ->
      "<div class='dative-error-page dative-resource-widget dative-form-object
        dative-paginated-item dative-widget-center ui-corner-all expanded'>
        <div class='dative-widget-header ui-widget-header ui-corner-top'>
          <div class='dative-widget-header-title
            container-center'>#{header}</div>
        </div>
        <div class='dative-widget-body'>#{content}</div>
      </div>"

    # We heard that a resource was destroyed. If the destroyed resource is the
    # one that we are currently displaying, then we hide it, close it, and
    # navigate to the home page.
    destroyResourceSuccess: (resourceModel) ->
      if @visibleView and
      @visibleView.model is @resourceModel and
      resourceModel.get('id') is @resourceModel.get('id') and
      resourceModel instanceof @resourceModel.constructor
        @visibleView.$el.slideUp
          complete: =>
            @closeVisibleView()
            @showHomePageView()

    # The information in this object controls how `@showResourcesView` behaves.
    # The `resourceName` param of that method must be an attribute of this
    # object. NOTE: default params not supplied here are filled in by
    # `@showResourcesViewSetDefaultOptions`.
    myResources:

      applicationSetting:
        resourcesViewClass: ApplicationSettingsView
        resourceViewClass: null
        resourceModelClass: null
        resourcesCollectionClass: null
        params:
          authenticationRequired: false
          needsAppSettings: true

      collection:
        resourcesViewClass: CollectionsView
        resourceViewClass: CollectionView
        resourceModelClass: CollectionModel
        resourcesCollectionClass: CollectionsCollection
        params:
          searchable: true

      corpus:
        resourcesViewClass: CorporaView
        resourceViewClass: null
        resourceModelClass: null
        resourcesCollectionClass: null
        params:
          needsAppSettings: true
          needsActiveFieldDBCorpus: true

      elicitationMethod:
        resourcesViewClass: ElicitationMethodsView
        resourceViewClass: ElicitationMethodView
        resourceModelClass: ElicitationMethodModel
        resourcesCollectionClass: ElicitationMethodsCollection

      file:
        resourcesViewClass: FilesView
        resourceViewClass: FileView
        resourceModelClass: FileModel
        resourcesCollectionClass: FilesCollection
        params:
          searchable: true

      form:
        resourcesViewClass: FormsView
        resourceViewClass: FormView
        resourceModelClass: FormModel
        resourcesCollectionClass: FormsCollection
        params:
          needsAppSettings: true
          searchable: true
          corpusElement: true
          needsActiveFieldDBCorpus: true
          importable: true

      keyboard:
        resourcesViewClass: KeyboardsView
        resourceViewClass: KeyboardView
        resourceModelClass: KeyboardModel
        resourcesCollectionClass: KeyboardsCollection

      languageModel:
        resourcesViewClass: LanguageModelsView
        resourceViewClass: LanguageModelView
        resourceModelClass: LanguageModelModel
        resourcesCollectionClass: LanguageModelsCollection

      language:
        resourcesViewClass: LanguagesView
        resourceViewClass: LanguageView
        resourceModelClass: LanguageModel
        resourcesCollectionClass: LanguagesCollection
        params:
          searchable: true

      morphologicalParser:
        resourcesViewClass: MorphologicalParsersView
        resourceViewClass: MorphologicalParserView
        resourceModelClass: MorphologicalParserModel
        resourcesCollectionClass: MorphologicalParsersCollection

      morphology:
        resourcesViewClass: MorphologiesView
        resourceViewClass: MorphologyView
        resourceModelClass: MorphologyModel
        resourcesCollectionClass: MorphologiesCollection

      orthography:
        resourcesViewClass: OrthographiesView
        resourceViewClass: OrthographyView
        resourceModelClass: OrthographyModel
        resourcesCollectionClass: OrthographiesCollection

      page:
        resourcesViewClass: PagesView
        resourceViewClass: PageView
        resourceModelClass: PageModel
        resourcesCollectionClass: PagesCollection

      phonology:
        resourcesViewClass: PhonologiesView
        resourceViewClass: PhonologyView
        resourceModelClass: PhonologyModel
        resourcesCollectionClass: PhonologiesCollection

      search:
        resourcesViewClass: SearchesView
        resourceViewClass: SearchView
        resourceModelClass: SearchModel
        resourcesCollectionClass: SearchesCollection
        params:
          searchable: true

      source:
        resourcesViewClass: SourcesView
        resourceViewClass: SourceView
        resourceModelClass: SourceModel
        resourcesCollectionClass: SourcesCollection
        params:
          searchable: true

      speaker:
        resourcesViewClass: SpeakersView
        resourceViewClass: SpeakerView
        resourceModelClass: SpeakerModel
        resourcesCollectionClass: SpeakersCollection

      subcorpus:
        resourcesViewClass: SubcorporaView
        resourceViewClass: SubcorpusView
        resourceModelClass: SubcorpusModel
        resourcesCollectionClass: SubcorporaCollection

      syntacticCategory:
        resourcesViewClass: SyntacticCategoriesView
        resourceViewClass: SyntacticCategoryView
        resourceModelClass: SyntacticCategoryModel
        resourcesCollectionClass: SyntacticCategoriesCollection

      tag:
        resourcesViewClass: TagsView
        resourceViewClass: TagView
        resourceModelClass: TagModel
        resourcesCollectionClass: TagsCollection

      user:
        resourcesViewClass: UsersView
        resourceViewClass: UserView
        resourceModelClass: UserModel
        resourcesCollectionClass: UsersCollection

    # Show the ResourcesView subclass for `resourceName` but also make sure
    # that the "Add a new resource" subview is rendered too.
    showNewResourceView: (resourceName) ->
      if not @loggedIn() then return
      resourcePlural = @utils.pluralize resourceName
      myViewAttr = "#{resourcePlural}View"
      if @[myViewAttr] and @visibleView is @[myViewAttr]
        @visibleView.toggleNewResourceViewAnimate()
      else
        @["show#{@utils.capitalize resourcePlural}View"]
          showNewResourceView: true

    # Show the ResourcesView subclass for `resourceName` but also make sure
    # that the "Import resources" subview is rendered too.
    showImportView: (resourceName) ->
      if not @loggedIn() then return
      resourcePlural = @utils.pluralize resourceName
      myViewAttr = "#{resourcePlural}View"
      if @[myViewAttr] and @visibleView is @[myViewAttr]
        @visibleView.toggleResourcesImportViewAnimate()
      else
        @["show#{@utils.capitalize resourcePlural}View"]
          showImportInterface: true

    # Return camelCase `resourceName` in a bunch of other forms that are useful
    # for dynamically displaying/manipulating that resource.
    getResourceNames: (resourceName) ->
      plural = @utils.pluralize resourceName
      regular = @utils.camel2regular resourceName
      hyphen = @utils.camel2hyphen resourceName
      regular: regular
      regPlur: @utils.pluralize regular
      hyphen: hyphen
      hypPlur: @utils.pluralize hyphen
      plural: plural
      capitalized: @utils.capitalize resourceName
      capPlur: @utils.capitalize plural

    # Get `obj[attr]`, returning `default` if `attr` is not a key of `obj`.
    get: (obj, attr, default_=null) ->
      if attr of obj then obj[attr] else default_

    # Return `options` with resource-specific values (from `@myResources`) and
    # defaults.
    showResourcesViewSetDefaultOptions: (resourceName, options={}) ->
      params = @myResources[resourceName].params or {}
      _.extend options, params
      # Authentication is required to view most resources views.
      options.authenticationRequired =
        @get options, 'authenticationRequired', true
      # Most resources views do not need to be passed app settings on init.
      options.needsAppSettings = @get options, 'needsAppSettings', false
      # When using FieldDB backend, the forms view needs the active FieldDB corpus.
      options.needsActiveFieldDBCorpus =
        @get options, 'needsActiveFieldDBCorpus', false
      # Most resources views are not searchable.
      options.searchable = @get options, 'searchable', false
      # Most resources views are not elements of a corpus (only forms).
      options.corpusElement = @get options, 'corpusElement', false
      options

    # Return `options` with resource-specific values (from `@myResources`) and
    # defaults.
    showResourceViewSetDefaultOptions: (resourceName, options={}) ->
      params = @myResources[resourceName].params or {}
      _.extend options, params
      # Authentication is required to view most resources views.
      options.authenticationRequired =
        @get options, 'authenticationRequired', true
      options

    # Return `true` if the FieldDB corpus has changed.
    fieldDBCorpusHasChanged: (myViewAttr, options={}) ->
      myViewAttr is 'formsView' and
      @activeServerType() is 'FieldDB' and
      options.fieldDBCorpusHasChanged

    closeView: (view) ->
      view.close()
      @closed view

    # Instantiate a new `ResourcesView` subclass for `resourceName`.
    instantiateResourcesView: (resourceName, options={}) ->
      myParams = {}
      if options.needsAppSettings
        myParams.model = @applicationSettings
        myParams.applicationSettings = @applicationSettings
      if options.needsActiveFieldDBCorpus
        myParams.activeFieldDBCorpus = @activeFieldDBCorpus
      new @myResources[resourceName].resourcesViewClass myParams

    # Alter the visible resources view so that it displays the "create a new
    # resource" view when rendered.
    showNewResourceViewOption: (o) ->
      if o.showNewResourceView
        @visibleView.newResourceViewVisible = true
        @visibleView.weShouldFocusFirstAddViewInput = true

    showImportInterfaceOption: (o) ->
      if o.showImportInterface
        if o.importable
          @visibleView.resourcesImportViewVisible = true

    # Alter a searchable resources view so that it has (or lacks) a search
    # object when rendered.
    searchableOption: (o) ->
      if o.searchable
        if o.search
          smartSearch = o.smartSearch or null
          @visibleView.setSearch o.search, smartSearch
        else
          @visibleView.deleteSearch()

    # Alter a view of resources that can be members of corpora so that the
    # resources view has (or lacks) a corpus that it should be displaying.
    corpusElementOption: (o) ->
      if o.corpusElement
        if o.corpus
          @visibleView.setCorpus o.corpus
        else
          @visibleView.deleteCorpus()


    ############################################################################
    # Show X-type resources view methods.
    # TODO: maybe these can all be dynamically defined too.
    ############################################################################

    showApplicationSettingsView: (options={}) ->
      @showResourcesView 'applicationSetting', options
    showCorporaView: (options={}) -> @showResourcesView 'corpus', options
    showFilesView: (options={}) -> @showResourcesView 'file', options
    showFormsView: (options={}) -> @showResourcesView 'form', options
    showLanguageModelsView: (options) ->
      @showResourcesView 'languageModel', options
    showMorphologicalParsersView: (options) ->
      @showResourcesView 'morphologicalParser', options
    showMorphologiesView: (options={}) ->
      @showResourcesView 'morphology', options
    showPagesView: (options={}) -> @showResourcesView 'page', options
    showPhonologiesView: (options={}) -> @showResourcesView 'phonology', options
    showSearchesView: (options) -> @showResourcesView 'search', options
    showSubcorporaView: (options={}) -> @showResourcesView 'subcorpus', options
    showUsersView: (options={}) -> @showResourcesView 'user', options


    ############################################################################
    # Show X-type "add a new" resource view methods (within the resources view)
    # TODO: maybe these can all be dynamically defined too.
    ############################################################################

    showNewFormView: -> @showNewResourceView 'form'
    showNewSubcorpusView: -> @showNewResourceView 'subcorpus'
    showNewPhonologyView: -> @showNewResourceView 'phonology'
    showNewMorphologyView: -> @showNewResourceView 'morphology'


    ############################################################################
    # Dialog-base view toggling.
    ############################################################################

    # Open/close the login dialog box
    toggleLoginDialog: -> Backbone.trigger 'loginDialog:toggle'

    openLoginDialogWithDefaults: (username, password) ->
      @loginDialog.dialogOpenWithDefaults
        username: username
        password: password

    # Open/close the register dialog box
    toggleRegisterDialog: -> Backbone.trigger 'registerDialog:toggle'

    # Open/close the alert dialog box
    toggleAlertDialog: -> Backbone.trigger 'alertDialog:toggle'

    # Open/close the tasks dialog box
    toggleTasksDialog: -> Backbone.trigger 'tasksDialog:toggle'

    # Open/close the help dialog box
    toggleHelpDialog: ->
      if not @helpDialog.hasBeenRendered
        @renderHelpDialog()
      Backbone.trigger 'helpDialog:toggle'


    ############################################################################
    # Change the jQuery UI CSS Theme
    ############################################################################

    # Change the theme if we're using the non-default one on startup.
    setTheme: ->
      activeTheme = @applicationSettings.get 'activeJQueryUITheme'
      defaultTheme = @applicationSettings.get 'defaultJQueryUITheme'
      if activeTheme isnt defaultTheme then @changeTheme()

    changeTheme: (event) ->

      # This is harder than it might at first seem.
      # Algorithm:
      # 1. get new CSS URL from selectmenu
      # 2. remove the current jQueryUI CSS <link>
      # 3. add a new jQueryUI CSS <link> with the new URL in its `href`
      # 4. ***CRUCIAL:*** when <link> `load` event fires, we ...
      # 5. get `BaseView.constructor` to refresh its `_jQueryUIColors`, which ...
      # 6. triggers a Backbone event indicating that the jQueryUI theme has changed, which ...
      # 7. causes `MainMenuView` to re-render.
      #
      # WARN: works for me on Mac with FF, Ch & Sa. Unsure of
      # cross-platform/browser support. May want to do feature detection and
      # employ a mixture of strategies 1-4.

      themeName = @applicationSettings.get 'activeJQueryUITheme'
      # TODO: this URL stuff should be in model
      newJQueryUICSSURL = "https://code.jquery.com/ui/1.11.2/themes/#{themeName}/jquery-ui.min.css"
      $jQueryUILinkElement = $('#jquery-ui-css')
      $jQueryUILinkElement.remove()
      $jQueryUILinkElement.attr href: newJQueryUICSSURL
      linkHTML = $jQueryUILinkElement.get(0).outerHTML
      $('#font-awesome-css').after linkHTML
      outerCallback = =>
        innerCallback = ->
          Backbone.trigger 'application-settings:jQueryUIThemeChanged'
        @constructor.refreshJQueryUIColors innerCallback
      @listenForLinkOnload outerCallback

      # Remaining TODOs:
      # 1. disable this feature when there is no Internet connection
      # 2. focus highlight doesn't match on login dialog (probably because it
      #    should be re-rendered after theme change)

    # Four strategies for detecting that a new CSS <link> has loaded.
    ############################################################################
    #
    # See http://www.phpied.com/when-is-a-stylesheet-really-loaded/

    # strategy #1
    listenForLinkOnload: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      if link
        link.onload = -> callback()

    # strategy #2
    addEventListenerToLink: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      eventListener = -> callback()
      if link && link.addEventListener
        link.addEventListener 'load', eventListener, false

    # strategy #3
    listenForReadyStateChange: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      if link
        link.onreadystatechange = ->
          state = link.readyState
          if state is 'loaded' or state is 'complete'
            link.onreadystatechange = null
            callback()

    # strategy #4
    checkForChangeInDocumentStyleSheets: (callback) ->
      cssnum = document.styleSheets.length
      func = ->
        if document.styleSheets.length > cssnum
          callback()
          clearInterval ti
      ti = setInterval func, 10


    ############################################################################
    # FieldDB .bug, .warn and .confirm hooks
    ############################################################################

    overrideFieldDBNotificationHooks: ->
      # Overriding FieldDB's logging hooks to do nothing
      FieldDB.FieldDBObject.verbose = -> {}
      FieldDB.FieldDBObject.debug = -> {}
      FieldDB.FieldDBObject.todo = -> {}
      FieldDB.FieldDBObject.bug = @displayBugReportDialog
      FieldDB.FieldDBObject.warn = @displayWarningMessagesDialog
      FieldDB.FieldDBObject.confirm = @displayConfirmDialog

    displayBugReportDialog: (message, optionalLocale) =>
      deferred = FieldDB.Q.defer()
      messageChannel = "bug:#{message?.replace /[^A-Za-z]/g, ''}"
      @listenTo Backbone, messageChannel, ->
        window.open(
          "https://docs.google.com/forms/d/18KcT_SO8YxG8QNlHValEztGmFpEc4-ZrjWO76lm0mUQ/viewform")
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: true

      options =
        text: message
        confirm: false
        confirmEvent: messageChannel
        confirmArgument: message
      Backbone.trigger 'openAlertDialog', options

      return deferred.promise

    displayWarningMessagesDialog: (message, message2, message3, message4) ->
      console.log message, message2, message3, message4

    displayConfirmDialog: (message, optionalLocale) =>
      # TODO @jrwdunham @cesine: figure out how i18n/localization works in
      # Dative.
      deferred = FieldDB.Q.defer()
      messageChannel = "confirm:#{message?.replace /[^A-Za-z]/g, ''}"

      @listenTo Backbone, messageChannel, ->
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: true

      @listenTo Backbone, "cancel#{messageChannel}", ->
        deferred.reject
          message: message
          optionalLocale: optionalLocale
          response: false

      options =
        text: message
        confirm: true
        confirmEvent: messageChannel
        cancelEvent: "cancel#{messageChannel}"
        confirmArgument: message
        cancelArgument: message
      Backbone.trigger 'openAlertDialog', options

      deferred.promise

    displayPromptDialog: (message, optionalLocale) ->
      deferred = FieldDB.Q.defer()
      messageChannel = "prompt:#{message?.replace /[^A-Za-z]/g, ''}"

      @listenTo Backbone, messageChannel, (userInput) ->
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: userInput

      @listenTo Backbone, "cancel#{messageChannel}", ->
        deferred.reject
          message: message
          optionalLocale: optionalLocale
          response: ""

      options =
        text: message
        confirm: true
        prompt: true
        confirmEvent: messageChannel
        cancelEvent: 'cancel' + messageChannel
        confirmArgument: message
        cancelArgument: message
      Backbone.trigger 'openAlertDialog', options

      deferred.promise

    displayConfirmIdentityDialog: (message, successCallback, failureCallback,
    cancelCallback) =>
      cancelCallback = cancelCallback or failureCallback
      if @applicationSettings.get 'fieldDBApplication' isnt
      FieldDB.FieldDBObject.application
        @applicationSettings.set 'fieldDBApplication',
          FieldDB.FieldDBObject.application
      @displayPromptDialog(message).then(
        (dialog) =>
          @applicationSettings
            .get('fieldDBApplication')
            .authentication
            .confirmIdentity(password: dialog.response)
            .then successCallback, failureCallback
      ,
        cancelCallback
      )

    # Change `attribute` to `value` in
    # `applicationSettings.get('<resource_name_plural>DisplaySettings').`
    changeDisplaySetting: (resource, attribute, value) ->
      try
        displaySettings = @applicationSettings.get "#{resource}DisplaySettings"
        displaySettings[attribute] = value
        @applicationSettings.save "#{resource}DisplaySettings", displaySettings


    ############################################################################
    # Resource Displayer Dialog logic
    ############################################################################
    #
    # These are the jQuery Dialog Boxes that are used to display a single
    # resource view.

    maxNoResourceDisplayerDialogs: 4

    getResourceDisplayerDialogs: ->
      for int in [1..@maxNoResourceDisplayerDialogs]
        @["resourceDisplayerDialog#{int}"] =
          new ResourceDisplayerDialogView index: int

    renderResourceDisplayerDialogs: ->
      for int in [1..@maxNoResourceDisplayerDialogs]
        @["resourceDisplayerDialog#{int}"]
          .setElement(@$("#resource-displayer-dialog-container-#{int}"))
          .render()
        @rendered @["resourceDisplayerDialog#{int}"]

    # Render the passed in resource view in the application-wide
    # `@resourceDisplayerDialog`
    showResourceInDialog: (resourceView) ->
      if @resourceViewAlreadyDisplayed resourceView
        Backbone.trigger 'resourceAlreadyDisplayedInDialog', resourceView
      else
        if not resourceView.model.collection
          collectionClass =
            @myResources[resourceView.resourceName].resourcesCollectionClass
          try
            resourceView.model.collection = new collectionClass()
        oldestResourceDisplayer = @getOldestResourceDisplayerDialog()
        oldestResourceDisplayer.showResourceView resourceView

    resourceViewAlreadyDisplayed: (resourceView) ->
      @resourceAlreadyDisplayed resourceView.model

    resourceAlreadyDisplayed: (resourceModel) ->
      isit = false
      for int in [1..@maxNoResourceDisplayerDialogs]
        try
          displayedModel = @["resourceDisplayerDialog#{int}"].resourceView.model
          if displayedModel.get('id') is resourceModel.get('id') and
          displayedModel.constructor.name is resourceModel.constructor.name
            isit = true
      isit

    getResourceViewClassFromResourceName: (resourceName) ->
      if resourceName is 'eventBasedKeyboard'
        EventBasedKeyboardView
      else
        @myResources[resourceName].resourceViewClass

    # Close all resource displayer dialogs.
    closeAllResourceDisplayerDialogs: ->
      for int in [1..@maxNoResourceDisplayerDialogs]
        @["resourceDisplayerDialog#{int}"].dialogClose()

    # The main menu view is telling us that the user has clicked on the small
    # keyboard icon in its top right. Note: we only display one active keyboard
    # at a time since, logically, there can only be one.
    showEventBasedKeyboardInDialog: (keyboardModel) ->
      if @activeKeyboard
        for int in [1..@maxNoResourceDisplayerDialogs]
          rdd = @["resourceDisplayerDialog#{int}"]
          if rdd.resourceView?.resourceName is 'keyboard'
            rdd.dialogClose()
            rdd.resourceView = null
      cb = =>
        @activeKeyboard = keyboardModel
        @showResourceModelInDialog @activeKeyboard, 'eventBasedKeyboard'
        @listenToOnce @activeKeyboard,
          'resourceDisplayerDialogHoldingModelClosed',
          @activeKeyboardClosed
      setTimeout cb, 600

    activeKeyboardClosed: -> @activeKeyboard = @getSystemWideKeyboard()

    # Create a view for the passed in `resourceModel` and render it in the
    # application-wide `@resourceDisplayerDialog`.
    showResourceModelInDialog: (resourceModel, resourceName) ->
      resourceViewClass = @getResourceViewClassFromResourceName resourceName
      resourceView = new resourceViewClass(model: resourceModel)
      if @resourceAlreadyDisplayed resourceModel
        Backbone.trigger 'resourceAlreadyDisplayedInDialog', resourceView
      else
        @showResourceInDialog resourceView

    getOldestResourceDisplayerDialog: ->
      oldest = @resourceDisplayerDialog1
      for int in [2..@maxNoResourceDisplayerDialogs]
        other = @["resourceDisplayerDialog#{int}"]
        if other.timestamp < oldest.timestamp then oldest = other
      oldest

    openExporterDialog: (options) ->
      @exporterDialog.setToBeExported options
      @exporterDialog.dialogOpen()

