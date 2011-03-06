# Public: Creates an element for editing annotations.
class Annotator.Editor extends Delegator

  # Events to be bound to @element.
  events:
    "form submit":                 "submit"
    ".annotator-save click":       "submit"
    ".annotator-cancel click":     "hide"
    ".annotator-cancel mouseover": "onCancelButtonMouseover"
    "textarea keydown":            "processKeypress"

  # Classes to toggle state.
  classes:
    hide:  'annotator-hide'
    focus: 'annotator-focus'

  # HTML template for @element.
  html: """
        <div class="annotator-outer annotator-editor">
          <form class="annotator-widget">
            <ul></ul>
            <div class="annotator-controls">
              <a href="#cancel" class="annotator-cancel">Cancel</a>
              <a href="#save" class="annotator-save annotator-focus">Save</a>
            </div>
            <span class="annotator-resize"></span>
          </form>
        <div>
        """

  options: {} # Configuration options

  # Public: Creates an instance of the Editor object. This will create the
  # @element from the @html string and set up all events.
  #
  # options - An Object literal containing options. There are currently no
  #           options implemented.
  #
  # Examples
  #
  #   # Creates a new editor, adds a custom field and
  #   # loads an annotation for editing.
  #   editor = new Annotator.Editor
  #   editor.addField({
  #     label: 'My custom input field',
  #     type:  'textarea'
  #     load:  someLoadCallback
  #     save:  someSaveCallback
  #   })
  #   editor.load(annotation)
  #
  # Returns a new Editor instance.
  constructor: (options) ->
    super $(@html)[0], options

    @fields = []
    @annotation = {}

    # Setup the default editor field.
    this.addField({
      type: 'textarea',
      label: 'Comments\u2026'
      load: (field, annotation) ->
        $(field).find('textarea').val(annotation.text || '')
      submit: (field, annotation) ->
        annotation.text = $(field).find('textarea').val()
    })

    this.setupDragabbles()

  # Public: Displays the Editor and fires a "show" event.
  # Can be used as an event callback and will call Event#preventDefault()
  # on the supplied event.
  #
  # event - Event object provided if method is called by event
  #         listener (default:undefined)
  #
  # Examples
  #
  #   # Displays the editor.
  #   editor.show()
  #
  #   # Displays the editor on click (prevents default action).
  #   $('a.show-editor').bind('click', editor.show)
  #
  # Returns itself.
  show: (event) =>
    event?.preventDefault()

    @element.removeClass(@classes.hide)
    @element.find('.annotator-save').addClass(@classes.focus)
    @element.find(':input:first').focus()
    this.publish('show')

  # Public: Hides the Editor and fires a "hide" event. Can be used as an event
  # callback and will call Event#preventDefault() on the supplied event.
  #
  # event - Event object provided if method is called by event
  #         listener (default:undefined)
  #
  # Examples
  #
  #   # Hides the editor.
  #   editor.hide()
  #
  #   # Hide the editor on click (prevents default action).
  #   $('a.hide-editor').bind('click', editor.hide)
  #
  # Returns itself.
  hide: (event) =>
    event?.preventDefault()

    @element.addClass(@classes.hide)
    this.publish('hide')

  # Public: Loads an annotation into the Editor and displays it setting
  # Editor#annotation to the provided annotation. It fires the "load" event
  # providing the current annotation subscribers can modify the annotation
  # before it updates the editor fields.
  #
  # annotation - An annotation Object to display for editing.
  #
  # Examples
  #
  #   # Diplays the editor with the annotation loaded.
  #   editor.load({text: 'My Annotation'})
  #
  #   editor.on('load', (annotation) ->
  #     console.log annotation.text
  #   ).load({text: 'My Annotation'})
  #   # => Outputs "My Annotation"
  #
  # Returns itself.
  load: (annotation) =>
    @annotation = annotation

    this.publish('load', [@annotation])

    for field in @fields
      field.load(field.element, @annotation)

    this.show();

  # Public: Hides the Editor and passes the anotation to all registered fields
  # so they can update it's state. It then fires the "save" event so that other
  # parties can further modify the annotation.
  # Can be used as an event callback and will call Event#preventDefault() on the
  # supplied event.
  #
  # event - Event object provided if method is called by event
  #         listener (default:undefined)
  #
  # Examples
  #
  #   # Submits the editor.
  #   editor.submit()
  #
  #   # Submits the editor on click (prevents default action).
  #   $('button.submit-editor').bind('click', editor.submit)
  #
  #   # Appends "Comment: " to the annotation comment text.
  #   editor.on('save', (annotation) ->
  #     annotation.text = "Comment: " + annotation.text
  #   ).submit()
  #
  # Returns itself.
  submit: (event) =>
    event?.preventDefault()

    for field in @fields
      field.submit(field.element, @annotation)

    this.publish('save', [@annotation])

    this.hide()

  # Public: Adds an addional form field to the editor. Callbacks can be provided
  # to update the view and anotations on load and submission.
  #
  # options - An options Object. Options are as follows:
  #           id     - A unique id for the form element will also be set as the
  #                    "for" attrubute of a label if there is one. Defaults to
  #                    a timestamp. (default: "annotator-field-{timestamp}")
  #           type   - Input type String. One of "input", "textarea", "checkbox"
  #                    (default: "input")
  #           label  - Label to display either in a label Element or as place-
  #                    holder text depending on the type. (default: "")
  #           load   - Callback Function called when the editor is loaded with a
  #                    new annotation. Recieves the field <li> element and the
  #                    annotation to be loaded.
  #           submit - Callback Function called when the editor is submitted.
  #                    Recieves the field <li> element and the annotation to be
  #                    updated.
  #
  # Examples
  #
  #   # Add a new input element.
  #   editor.addField({
  #     label: "Tags",
  #
  #     # This is called when the editor is loaded use it to update your input.
  #     load: (field, annotation) ->
  #       # Do something with the annotation.
  #       value = getTagString(annotation.tags)
  #       $(field).find('input').val(value)
  #
  #     # This is called when the editor is submitted use it to retrieve data
  #     # from your input and save it to the annotation.
  #     submit: (field, annotation) ->
  #       value = $(field).find('input').val()
  #       annotation.tags = getTagsFromString(value)
  #   })
  #
  #   # Add a new checkbox element.
  #   editor.addField({
  #     type: 'checkbox',
  #     id: 'annotator-field-my-checkbox',
  #     label: 'Allow anyone to see this annotation',
  #     load: (field, annotation) ->
  #       # Check what state of input should be.
  #       if checked
  #         $(field).find('input').attr('checked', 'checked')
  #       else
  #         $(field).find('input').removeAttr('checked')

  #     submit: (field, annotation) ->
  #       checked = $(field).find('input').is(':checked')
  #       # Do something.
  #   })
  #
  # Returns the created <li> Element.
  addField: (options) ->
    field = $.extend({
      id:     'annotator-field-' + (new Date()).getTime()
      type:   'input'
      label:  ''
      load:   ->
      submit: ->
    }, options)

    input = null
    element = $('<li />')
    field.element = element[0]

    switch (field.type)
      when 'textarea'          then input = $('<textarea />')
      when 'input', 'checkbox' then input = $('<input />')

    element.append(input);

    input.attr({
      id: field.id
      placeholder: field.label
    })

    if field.type == 'checkbox'
      input[0].type = 'checkbox'
      element.addClass('annotator-checkbox')
      element.append($('<label />', {for: field.id, html: field.label}))

    @element.find('ul:first').append(element)

    @fields.push field

    field.element

  # Event callback. Listens for the following special keypresses.
  # - escape: Hides the editor
  # - enter:  Submits the editor
  #
  # event - A keydown Event object.
  #
  # Returns nothing
  processKeypress: (event) =>
    if event.keyCode is 27 # "Escape" key => abort.
      this.hide()
    else if event.keyCode is 13 and !event.shiftKey
      # If "return" was pressed without the shift key, we're done.
      this.submit()

  # Event callback. Removes the focus class from the submit button when the
  # cancel button is hovered.
  #
  # Returns nothing
  onCancelButtonMouseover: =>
    @element.find('.' + @classes.focus).removeClass(@classes.focus);

  # Sets up mouse events for resizing and dragging the editor window.
  # window events are bound only when needed and throttled to only update
  # the positions at most 60 times a second.
  #
  # Returns nothing.
  setupDragabbles: () ->
    mousedown = null
    editor    = @element
    resize    = editor.find('.annotator-resize')
    textarea  = editor.find('textarea:first')
    controls  = editor.find('.annotator-controls')
    throttle  = false

    onMousedown = (event) ->
      if event.target == this
        mousedown = {
          element: this
          top:     event.pageY
          left:    event.pageX
        }

        $(window).bind({
          'mouseup.annotator-editor-resize':   onMouseup
          'mousemove.annotator-editor-resize': onMousemove
        })
        event.preventDefault();

    onMouseup = ->
      mousedown = null;
      $(window).unbind '.annotator-editor-resize'

    onMousemove = (event) ->
      if mousedown and throttle == false
        diff = {
          top:  event.pageY - mousedown.top
          left: event.pageX - mousedown.left
        }

        if mousedown.element == resize[0]
          height = textarea.outerHeight()
          width  = textarea.outerWidth()

          textarea.height(height - diff.top)
          textarea.width(width + diff.left)

          # Only update the mousedown object if the dimensions
          # have changed, otherwise they have reached thier minimum
          # values.
          mousedown.top  = event.pageY unless textarea.outerHeight() == height
          mousedown.left = event.pageX unless textarea.outerWidth()  == width

        else if mousedown.element == controls[0]
          editor.css({
            top:  parseInt(editor.css('top'), 10)  + diff.top
            left: parseInt(editor.css('left'), 10) + diff.left
          })

          mousedown.top  = event.pageY
          mousedown.left = event.pageX

        throttle = true;
        setTimeout(->
          throttle = false
        , 1000/60);

    resize.bind   'mousedown', onMousedown
    controls.bind 'mousedown', onMousedown
