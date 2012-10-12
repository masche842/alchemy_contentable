(($, window, document) ->

  if (typeof(Alchemy) is 'undefined')
    window.Alchemy = {}

  $.extend(Alchemy,

    openContentableTrashWindow: (contentable_id, contentable_type, title) ->
      size_x = 380
      size_y = 270
      if (size_x == 'fullscreen')
        size_x = $(window).width() - 50
        size_y = $(window).height() - 50
      $dialog = $('<div style="display:none" id="alchemyTrashWindow"></div>')
      $dialog.appendTo('body')
      $dialog.html(Alchemy.getOverlaySpinner({x: size_x,y: size_y}))
      Alchemy.trashWindow = $dialog.dialog({
        modal: false
        width: 380
        minHeight: 450
        maxHeight: $(window).height() - 50
        title: title
        resizable: false
        show: "fade"
        hide: "fade"
        open: (event, ui) ->
          $.ajax({
            url: Alchemy.routes.contentable_admin_trash_path(contentable_id, contentable_type),
            success: (data, textStatus, XMLHttpRequest) ->
              $dialog.html(data)
              # Need this for DragnDrop elements into elements window.
              # Badly this is screwing up maxHeight option
              $dialog.css({
                overflow: 'visible'
              }).dialog('widget').css({
                overflow: 'visible'
              })
              Alchemy.overlayObserver('#alchemyTrashWindow')
            error: (XMLHttpRequest, textStatus, errorThrown) ->
              Alchemy.AjaxErrorHandler($dialog, XMLHttpRequest.status, textStatus, errorThrown)
          })
        close: ->
          $dialog.remove()
      })

    refreshTrashWindow: (contentable_id, contentable_type) ->
      if ($('#alchemyTrashWindow').length > 0)
        $('#alchemyTrashWindow').html(Alchemy.getOverlaySpinner({x: 380,y: 270}))
        $.get(Alchemy.routes.admin_trash_path(contentable_id, contentable_type), (html) ->
          $('#alchemyTrashWindow').html(html)
        )

  )
)(jQuery, window, document)