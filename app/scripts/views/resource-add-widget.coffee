define [
  './base'
  './textarea-field'
  './../models/resource'
  './../utils/globals'
  './../templates/resource-add-widget'
], (BaseView, TextareaFieldView, ResourceModel, globals, resourceAddTemplate) ->

  # Resource Add Widget View
  # -------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # resource and updating an existing one.

  class ResourceAddWidgetView extends BaseView

    ############################################################################
    # Attributes that should be overridden in sub-classes.
    ############################################################################

    # The name of the resource (e.g., 'phonology'); it should be singular and
    # uncapitalized.
    resourceName: 'resource'

    # The Backbone model for the resource.
    resourceModel: ResourceModel

    # The primary attributes: those that will have their input fields displayed
    # by default.
    primaryAttributes: []

    # The secondary attributes that users can modify; i.e., the modifiable
    # attributes whose input fields will only be shown when the "show secondary
    # input fields" button is clicked.
    editableSecondaryAttributes: []

    template: resourceAddTemplate
    className: 'add-resource-widget dative-widget-center dative-shadowed-widget
      ui-widget ui-widget-content ui-corner-all'

    initialize: (options) ->
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural
      @activeServerType = @getActiveServerType()
      @secondaryDataVisible = false
      @listenToEvents()
      @addUpdateType = options.addUpdateType or 'add'
      @submitAttempted = false

      # TODO: if this is an "add"-type form, then the original model copy
      # should (maybe) be an empty resource.
      @originalModelCopy = @copyModel @model
      if @addUpdateType is 'add'
        @originalModelCopy.set @getEmptyModelObject()

    copyModel: (inputModel) ->
      newModel = new @resourceModel()
      for attr, val of @model.attributes
        inputValue = @utils.clone inputModel.get(attr)
        newModel.set attr, inputValue
      newModel

    render: ->
      console.log 'resource add widget being rendered here'
      if @activeServerTypeIsOLD() and not @weHaveNewResourceData()
        console.log 'we need to get new resource data before rendering a resource add widget'
        @model.getNewResourceData() # Success in this request will call `@render()`
        return
      @getFieldViews()
      @html()
      @secondaryDataVisibility()
      @renderFieldViews()
      @guify()
      @fixRoundedBorders() # defined in BaseView
      @listenToEvents()
      @

    events:
      'click button.add-resource-button':          'submitForm'
      'click button.hide-resource-add-widget':     'hideSelf'
      'click button.toggle-secondary-data-fields': 'toggleSecondaryDataAnimate'
      'click button.resource-add-help':            'openResourceAddHelp'
      'click button.clear-form':                   'clear'
      'click button.undo-changes':                 'undoChanges'
      'keydown':                                   'keydown'

    listenToEvents: ->
      super
      # Events specific to an OLD backend and the request for the data needed to create a resource.
      @listenTo Backbone, "getNew#{@resourceNameCapitalized}DataStart",
        @getNewResourceDataStart
      @listenTo Backbone, "getNew#{@resourceNameCapitalized}DataEnd",
        @getNewResourceDataEnd
      @listenTo Backbone, "getNew#{@resourceNameCapitalized}DataSuccess",
        @getNewResourceDataSuccess
      @listenTo Backbone, "getNew#{@resourceNameCapitalized}DataFail",
        @getNewResourceDataFail

      @listenTo @model, "add#{@resourceNameCapitalized}Start", @addResourceStart
      @listenTo @model, "add#{@resourceNameCapitalized}End", @addResourceEnd
      @listenTo @model, "add#{@resourceNameCapitalized}Fail", @addResourceFail

      @listenTo @model, "update#{@resourceNameCapitalized}Start", @addResourceStart
      @listenTo @model, "update#{@resourceNameCapitalized}End", @addResourceEnd
      @listenTo @model, "update#{@resourceNameCapitalized}Fail", @updateResourceFail
      @listenTo @model, "update#{@resourceNameCapitalized}Success", @updateResourceSuccess

      @listenToFieldViews()

    listenToFieldViews: ->
      for fieldView in @fieldViews()
        @listenTo fieldView, 'submit', @submitForm
        @listenTo fieldView, 'focusPreviousField', @focusPreviousField

    # Write the initial HTML to the page.
    html: ->
      context =
        addUpdateType: @addUpdateType
        headerTitle: @getHeaderTitle()
        activeServerType: @getActiveServerType()
        resourceName: @resourceName
        resourceNameHuman: @utils.camel2regular @resourceName
      @$el
        .attr 'id', @model.cid
        .html @template(context)

    getHeaderTitle: ->
      if @addUpdateType is 'add'
        "Add a #{@resourceNameCapitalized}"
      else
        "Update this #{@resourceName}"

    propagateSubmitAttempted: ->
      for fieldView in @fieldViews()
        fieldView.submitAttempted = true

    # Add the names of attributes here that the client canNOT alter. This is
    # useful because sometimes the server will alter these and we don't
    # (necessarily) want server-side modifications to cause `modelAltered()` to
    # return `true`.
    # TODO: maybe the `editableAttributes` of the model serve this purpose.
    clientSideUnalterableAttributes: [
      'datetime_modified'
      'datetime_entered'
      'modifier'
      'enterer'
      'compile_attempt'
      'compile_message'
      'compile_succeeded'
      'generate_attempt'
      'generate_message'
      'generate_succeeded'
    ]

    modelAltered: ->
      for attr, val of @model.attributes
        if attr not in @clientSideUnalterableAttributes
          originalValue = @originalModelCopy.get attr
          currentValue = @model.get attr
          if not _.isEqual originalValue, currentValue
            return true
      return false

    submitForm: (event) ->
      if @modelAltered()
        @submitAttempted = true
        @propagateSubmitAttempted()
        @stopEvent event
        # Here is the problem
        @setToModel()
        @disableForm()
        clientSideValidationErrors = @model.validate()
        if clientSideValidationErrors
          for attribute, error of clientSideValidationErrors
            @model.trigger "validationError:#{attribute}", error
          msg = 'See the error message(s) beneath the input fields.'
          Backbone.trigger "#{@addUpdateType}#{@resourceNameCapitalized}Fail", msg, @model
          @enableForm()
        else
          if @addUpdateType is 'add'
            @model.collection.addResource @model
          else
            @model.collection.updateResource @model
      else
        Backbone.trigger("#{@addUpdateType}#{@resourceNameCapitalized}Fail",
          'Please make some changes before attempting to save.', @model)

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '-15%'
      options.color = @constructor.jQueryUIColors().errCo
      options

    spin: -> @$('.spinner-container').spin @spinnerOptions()

    stopSpin: -> @$('.spinner-container').spin false

    # Disable form input fields and submit button
    disableForm: ->
      @$('button.add-resource-button').button 'disable'
      @disableFieldViews()

    disableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.disable()

    # Enable form input fields and submit button
    enableForm: ->
      @$('button.add-resource-button').button 'enable'
      @enableFieldViews()

    enableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.enable()

    addResourceStart: -> @spin()

    addResourceEnd: ->
      @enableForm()
      @stopSpin()

    addResourceFail: (error) ->
      # The field views are listening for specific `validationError` events on
      # the resource model. They will handle their own validation stuff.
      Backbone.trigger "add#{@resourceNameCapitalized}Fail", error, @model

    updateResourceFail: (error) ->
      Backbone.trigger "update#{@resourceNameCapitalized}Fail", error, @model

    updateResourceSuccess: ->
      @originalModelCopy = @copyModel @model
      Backbone.trigger "update#{@resourceNameCapitalized}Success", @model

    # Set the state of the "add a resource" HTML form on the Dative resource
    # model.
    #setToModel: -> fv.setToModel() for fv in @fieldViews()
    setToModel: ->
      fv.setToModel() for fv in @fieldViews()

    # Focus the previous field. This is a hack that is required because the
    # multiSelect does not correctly move the focus on a Shift+Tab event.
    focusPreviousField: ->
      $focusedElement = @$ ':focus'
      inputSelector = 'textarea, .ms-list, .ui-selectmenu-button, button'
      $focusedElement
        .closest('li.dative-form-field')
        .prev()
          .find(inputSelector).first().focus()

    # Tell the Help dialog to open itself and search for "adding a resource" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openResourceAddHelp: ->
      if @addUpdateType is 'add'
        searchTerm = "adding a #{@resourceName}"
      else
        searchTerm = "updating a #{@resourceName}"
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    # <Enter> on a closed resource opens it, <Esc> on an open resource closes
    # it.
    keydown: (event) ->
      switch event.which
        when 27
          @stopEvent event
          @hideSelf()

    activeServerTypeIsOLD: -> @getActiveServerType() is 'OLD'

    primaryDataSelector: 'ul.primary-data'

    secondaryDataSelector: 'ul.secondary-data'


    ############################################################################
    # Getting, configuring & rendering field sub-views
    ############################################################################

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView: {}

    # Return the appropriate FieldView (subclass) instance for a given
    # attribute, as specified in `@attribute2fieldView`. The default field view
    # is `TextareaFieldView`.
    getFieldView: (attribute) ->
      params = # All `FieldView` subclasses expect `attribute` and `model` on init
        resource: @resourceNamePlural
        attribute: attribute # e.g., "name"
        model: @model
        options: @getOptions() # These are the OLD-specific <select> options relevant to the resource, cf. GET requests to <resource_name_plural>/new
      if attribute of @attribute2fieldView
        MyFieldView = @attribute2fieldView[attribute]
        new MyFieldView params
      else # the default field view is a(n expandable) textarea.
        new TextareaFieldView params

    # Put the appropriate FieldView instances in `@primaryFieldViews` and.
    # `@secondaryFieldViews`
    getFieldViews: ->
      @getPrimaryFieldViews()
      @getSecondaryFieldViews()

    # Put the appropriate FieldView instances in `@primaryFieldViews`.
    getPrimaryFieldViews: ->
      @primaryFieldViews = []
      for attribute in @primaryAttributes
        @primaryFieldViews.push @getFieldView attribute

    # Put the appropriate FieldView instances in `@secondaryFieldViews`.
    getSecondaryFieldViews: ->
      @secondaryFieldViews = []
      for attribute in @editableSecondaryAttributes
        @secondaryFieldViews.push @getFieldView attribute

    fieldViews: ->
      try
        @primaryFieldViews.concat @secondaryFieldViews
      catch
        []

    renderFieldViews: ->
      @renderPrimaryFieldViews()
      @renderSecondaryFieldViews()

    renderPrimaryFieldViews: ->
      $primaryDataUL = @$ @primaryDataSelector
      for fieldView in @primaryFieldViews
        $primaryDataUL.append fieldView.render().el
        @rendered fieldView

    renderSecondaryFieldViews: ->
      $secondaryDataUL = @$ @secondaryDataSelector
      for fieldView in @secondaryFieldViews
        $secondaryDataUL.append fieldView.render().el
        @rendered fieldView


    ############################################################################
    # OLD input options (i.e., possible speakers, users, categories, etc.)
    ############################################################################

    # Returns true of `globals` has a key for `resourceData`. The value of
    # this key is an object containing a subset of the following keys:
    # `form_searches`, `users`, `tags`, and `corpus_formats`.
    weHaveNewResourceData: -> globals["#{@resourceName}Data"]?

    # Return an object representing the options for forced-choice inputs.
    # Currently only relevant for the OLD.
    getOptions: ->
      if globals["#{@resourceName}Data"]
        globals["#{@resourceName}Data"]
      else
        {}

    getNewResourceDataStart: -> @spin()

    getNewResourceDataEnd: -> @stopSpin()

    getNewResourceDataSuccess: (data) ->
      @storeOptionsDataGlobally data
      @render()

    storeOptionsDataGlobally: (data) ->
      globals["#{@resourceName}Data"] = data

    getNewResourceDataFail: ->
      console.log "Failed to retrieve the data from the OLD server which is
        necessary for creating a new #{@resourceName}"


    ############################################################################
    # jQuery (UI) GUI stuff.
    ############################################################################

    # Make the vanilla HTML nice and jQueryUI-ified.
    guify: ->
      @buttonify()
      @tooltipify()
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    # Make the buttons into jQuery buttons.
    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

      # Make all of righthand-side buttons into jQuery buttons and set the
      # position of their tooltips programmatically based on their
      # position/index.
      @$(@$('.button-container-right button').get().reverse())
        .each (index, element) =>
          leftOffset = (index * 35) + 10
          @$(element)
            .button()
            .tooltip
              position:
                my: "left+#{leftOffset} center"
                at: "right center"
                collision: "flipfit"

    # Make the `title` attributes of the inputs/controls into jQueryUI tooltips.
    tooltipify: ->
      @$('.dative-widget-header .hide-resource-add-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-header .toggle-secondary-data-fields.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-70')
      @$('button.add-resource-button')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.toggle-secondary-data-fields')
        .tooltip position: @tooltipPositionLeft('-90')

    # Reset the model to its default state.
    clear: ->
      @model.set @getEmptyModelObject()
      @refresh()

    # Undo the (unsaved!) changes to the resource (made presumably via the update
    # interface): restore the model to its pre-modified state.
    undoChanges: ->
      for attr, val of @originalModelCopy.attributes
        @model.set attr, @originalModelCopy.get(attr)
      @refresh()
      @setToModel()
      @originalModelCopy = @copyModel @model
      @validate()
      # ResourceView listens for the following and calls `indicateModelState`.
      @trigger 'forceModelChanged'

    validate: ->
      errors = @model.validate()
      for fieldView in @fieldViews()
        fieldView.validate errors

    # Tell all field views to refresh themselves to match the current state of
    # the model.
    refresh: ->
      for fieldView in @fieldViews()
        fieldView.refresh @model

    # Return a JS object representing an empty resource model: note that this
    # crucially "empties" the editable attributes; that is, a resource's id,
    # its enterer, etc., will not be represented in the returned model object.
    getEmptyModelObject: ->
      modelDefaults = @utils.clone @model.defaults()
      emptyModelObject = {}
      for attribute in @editableSecondaryAttributes.concat @primaryAttributes
        emptyModelObject[attribute] = modelDefaults[attribute]
      emptyModelObject

    ############################################################################
    # Showing, hiding and toggling
    ############################################################################

    # The ResourcesView will handle this hiding.
    hideSelf: -> @trigger "#{@resourceName}AddView:hide"

    # If the secondary data fields should be visible, show them; otherwise no.
    secondaryDataVisibility: ->
      if @secondaryDataVisible
        @showSecondaryData()
      else
        @hideSecondaryData()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).hide()

    showSecondaryData: ->
      @secondaryDataVisible = true
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).show()

    hideSecondaryDataAnimate: ->
      @secondaryDataVisible = false
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).slideUp()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).slideDown
        complete: =>
          @$(@secondaryDataSelector).find('textarea').first().focus()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    toggleSecondaryDataAnimate: ->
      if @secondaryDataVisible
        @hideSecondaryDataAnimate()
      else
        @showSecondaryDataAnimate()

    # Make the "toggle secondary data" button have the appropriate icon and
    # tooltip.
    setSecondaryDataToggleButtonState: ->
      if @secondaryDataVisible
        @$('button.toggle-secondary-data-fields')
          .tooltip
            content: 'hide the secondary data input fields'
          .find('i')
            .removeClass 'fa-angle-down'
            .addClass 'fa-angle-up'
      else
        @$('button.toggle-secondary-data-fields')
          .tooltip
            content: 'show the secondary data input fields'
          .find('i')
            .removeClass 'fa-angle-up'
            .addClass 'fa-angle-down'


