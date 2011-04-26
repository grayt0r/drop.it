class window.Dilih
	
	options =
		revertOnDropOff: false
		snap: 6
		draggables: '.draggable'
		droppables: '.droppable'
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
		
		delegateDrag: false
		delegateContainer: 'body'
		delegateSelector: '.draggable'
		updateDroppablesOnDrag: false
		cloneDrag: false
	
	constructor: (o) ->
		@options = $.extend {}, options, o
		@draggables = $(@options.draggables)
		@overed = null
		
		@updateDroppables()
		
		@mouse =
			'now': {}
			'pos': {}
			'start': {}
		@value =
			'start': {}
			'now': {}
			
		@attach()
		
	attach: ->
		if @options.delegateDrag
			$(@options.delegateContainer).delegate @options.delegateSelector, 'mousedown', (event) =>
				@element = $(event.target)
				@start event
		else
			@draggables.bind 'mousedown', (event) =>
				@element = $(event.target)
				@start event
		
	detach: ->
		@element.unbind 'mousedown', @start

	start: (event) =>
		# if it's not a left click, do nothing
		if (event.which != 1) then return
		
		if @options.cloneDrag
			currentOffset = @element.offset()
			@element = @element.clone().css
				'opacity': 0.5
				'position': 'absolute'
				'left': currentOffset.left
				'top': currentOffset.top
			$('body').append @element
		
		@mouse.start = 
			x: event.pageX
			y: event.pageY
		#console.log "[start] mouse.start x,y = #{@mouse.start.x},#{@mouse.start.y}"
		
		# clone?
		@value.start =
			x: parseInt(@element.css('left')) || 0
			y: parseInt(@element.css('top')) || 0
		
		@value.now =
			x: parseInt(@element.css('left')) || 0
			y: parseInt(@element.css('top')) || 0
		#console.log "[start] value.now x,y = #{@value.now.x},#{@value.now.y}"
		
		@mouse.pos =
			x: @mouse.start.x - @value.now.x
			y: @mouse.start.y - @value.now.y
		
		# right place?
		if @options.updateDroppablesOnDrag then @updateDroppables()
				
		# @document
		$(document).bind
			mousemove: @check
			mouseup: @cancel
			mousedown: @eventStop
	
	check: (event) =>
		console.log "[check]"
		
		distance = Math.round(Math.sqrt(Math.pow(event.pageX - @mouse.start.x, 2) + Math.pow(event.pageY - @mouse.start.y, 2)))
		#console.log "[check] distance=#{distance}, options.snap=#{options.snap}"
		
		if distance > @options.snap
			@cancel()
			
			$(document).bind
				mousemove: @drag
				mouseup: @stop
			
			@element.trigger 'start', [@element]
			@options.onStart.call @, @element
		
	drag: (event) =>
		console.log "[drag]"
		@mouse.now = 
			x: event.pageX
			y: event.pageY
		#console.log "[drag] @mouse.now.x=#{@mouse.now.x}, @mouse.now.y=#{@mouse.now.y}"
		
		@value.now = 
			x: @mouse.now.x - @mouse.pos.x
			y: @mouse.now.y - @mouse.pos.y
		
		#console.log "[drag] @value.now.x=#{@value.now.x}, @value.now.y=#{@value.now.y}"
		
		@element.css
			'left': "#{@value.now.x}px"
			'top': "#{@value.now.y}px"
		
		@element.trigger 'drag', [@element]
		@options.onDrag.call @, @element
		
		if @droppables.length then @checkDroppables()
	
	cancel: (event) =>
		$(document).unbind
			mousemove: @check
			mouseup: @cancel
		
		# why?
		if event
			$(document).unbind 'mousedown', @eventStop
			
			@element.trigger 'cancel', [@element]
			@options.onCancel.call @, @element
		
	stop: (event) =>
		console.log "[stop]"
		
		@checkDroppables()
		
		@element.trigger 'drop', [@element, @overed]
		@options.onDrop.call @, @element, @overed
		
		if @overed.length
			@options.onDropOn.call @, @element, @overed
		else
			if @options.revertOnDropOff then @revert()
			@options.onDropOff.call @, @element
		
		@overed = null
		
		$(document).unbind
			mousemove: @drag
			mouseup: @stop
			mousedown: @eventStop
		
		if event
			@element.trigger 'complete', [@element]
			@options.onComplete.call @, @element
	
	eventStop: (event) =>
		return false
	
	checkDroppables: ->
		overed_array = @droppables.filter (i, el) =>
			d = @getDroppableCoordinates(el)
			now = @mouse.now
			now.x > d.left && now.x < d.right && now.y < d.bottom && now.y > d.top
		
		overed = overed_array.last()
		
		if @overed != overed
			if @overed
				@overed.trigger 'leave', [@element, @overed]
				@options.onLeave.call @, @element, @overed
			
			if overed
				overed.trigger 'enter', [@element, overed]
				@options.onEnter.call @, @element, overed
			
			@overed = overed
		
	getDroppableCoordinates: (el) ->
		el = $(el)
		offset = el.offset()
		position =
			left: offset.left
			right: offset.left + el.width()
			top: offset.top
			bottom: offset.top + el.height()
		# TODO: deal with fixed elements
		
	revert: ->
		@element.animate({
			left: "#{@value.start.x}px"
			top: "#{@value.start.y}px"
		}, =>
			@options.onRevertComplete.call @, @element
		)
	
	updateDroppables: (selector = @options.droppables) ->
		@droppables = $(selector)