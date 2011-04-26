class window.Dilih
	
	options =
		draggables: '.draggable'
		droppables: '.droppable'
		snap: 6
		revertOnDropOff: false
		delegateDrag: false
		delegateContainer: 'body'
		delegateSelector: '.draggable'
		updateDroppablesOnDrag: false
		ghost: false
		# TODO: Best way to handle events?
		onStart: (thisEl) ->
		onDrag: (thisEl) ->
		onCancel: (thisEl) ->
		onDrop: (thisEl) ->
		onDropOn: (thisEl, dropEl) ->
		onDropOff: (thisEl) ->
		onComplete: (thisEl, dropEl) ->
		onEnter: (thisEl, dropEl) ->
		onLeave: (thisEl, dropEl) ->
		onRevertComplete: (thisEl) ->
	
	constructor: (o) ->
		@options = $.extend {}, options, o
		@draggables = $(@options.draggables)
		@activeDrops = null
		
		@updateDroppables()
		
		@positions =
			'mouse':
				'start': {}
				'current': {}
			'element':
				'start': {}
				'current': {}
			'offset': {}
			
		# Attach initial events
		if @options.delegateDrag
			$(@options.delegateContainer).delegate @options.delegateSelector, 'mousedown', @start
		else
			@draggables.bind 'mousedown', @start

	start: (event) =>
		# If it's not a left click, do nothing
		if (event.which != 1) then return
		
		@element = $(event.target)
		
		if @options.ghost
			currentOffset = @element.offset()
			@element = @element.clone().css({
				'opacity': 0.5
				'position': 'absolute'
				'left': currentOffset.left
				'top': currentOffset.top
			}).appendTo($('body'))
		
		@positions.mouse.start = 
			x: event.pageX
			y: event.pageY
		
		@positions.element.start =
			x: parseInt(@element.css 'left') || 0
			y: parseInt(@element.css 'top') || 0
		
		@positions.offset =
			x: @positions.mouse.start.x - @positions.element.start.x
			y: @positions.mouse.start.y - @positions.element.start.y
		
		if @options.updateDroppablesOnDrag then @updateDroppables()
				
		$(document).bind
			mousemove: @check
			mouseup: @cancel
			mousedown: @eventStop
	
	check: (event) =>
		distance = Math.round(Math.sqrt(Math.pow(event.pageX - @positions.mouse.start.x, 2) + Math.pow(event.pageY - @positions.mouse.start.y, 2)))
		
		if distance > @options.snap
			@cancel()
			
			$(document).bind
				mousemove: @drag
				mouseup: @stop
			
			# TODO: Sort events
			@element.trigger 'start', [@element]
			@options.onStart.call @, @element
	
	cancel: (event) =>
		$(document).unbind
			mousemove: @check
			mouseup: @cancel

		# If the cancel is triggered by the user, remove the remaining events
		if event
			$(document).unbind 'mousedown', @eventStop
			
			# TODO: Sort events
			@element.trigger 'cancel', [@element]
			@options.onCancel.call @, @element
	
	eventStop: -> return false
		
	drag: (event) =>
		@positions.mouse.current = 
			x: event.pageX
			y: event.pageY
		
		@positions.element.current = 
			x: @positions.mouse.current.x - @positions.offset.x
			y: @positions.mouse.current.y - @positions.offset.y
		
		@element.css
			'left': "#{@positions.element.current.x}px"
			'top': "#{@positions.element.current.y}px"
		
		# TODO: Sort events
		@element.trigger 'drag', [@element]
		@options.onDrag.call @, @element
		
		if @droppables.length then @checkDroppables()
	
	stop: (event) =>
		@checkDroppables()
		
		# TODO: Sort events
		@element.trigger 'drop', [@element, @activeDrops]
		@options.onDrop.call @, @element, @activeDrops
		
		if @activeDrops.length
			@options.onDropOn.call @, @element, @activeDrops
		else
			if @options.revertOnDropOff then @revert()
			@options.onDropOff.call @, @element
		
		@activeDrops = null
		
		$(document).unbind
			mousemove: @drag
			mouseup: @stop
			mousedown: @eventStop
		
		# TODO: Sort events
		@element.trigger 'complete', [@element]
		@options.onComplete.call @, @element
	
	checkDroppables: ->
		# Calculate which (if any) droppables the mouse is currently over
		activeDrops = @droppables.filter((i, el) =>
			d = @getDroppableCoordinates(el)
			mc = @positions.mouse.current
			mc.x > d.left && mc.x < d.right && mc.y < d.bottom && mc.y > d.top
		).last()
		
		if @activeDrops != activeDrops
			if @activeDrops
				# TODO: Sort events
				@activeDrops.trigger 'leave', [@element, @activeDrops]
				@options.onLeave.call @, @element, @activeDrops
			
			if activeDrops
				# TODO: Sort events
				activeDrops.trigger 'enter', [@element, activeDrops]
				@options.onEnter.call @, @element, activeDrops
			
			@activeDrops = activeDrops
		
	getDroppableCoordinates: (el) ->
		el = $(el)
		offset = el.offset()
		return {
			left: offset.left
			right: offset.left + el.width()
			top: offset.top
			bottom: offset.top + el.height()
		}
		# TODO: Deal with fixed elements
		
	revert: ->
		@element.animate({
			left: "#{@positions.element.start.x}px"
			top: "#{@positions.element.start.y}px"
		}, =>
			@options.onRevertComplete.call @, @element
		)
	
	updateDroppables: (selector = @options.droppables) ->
		@droppables = $(selector)