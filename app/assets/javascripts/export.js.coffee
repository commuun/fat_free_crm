(($) ->

  $(document).on 'click', 'a.export-link', (event) ->
    event.preventDefault()

    $('form.export-form').show()
    $('form.export-form').attr( 'action', $(this).attr('href') )


  $(document).on 'submit', 'form.export-form', (event) ->
    event.preventDefault()

    href = $(this).attr('action')
    comment = $(this).children('textarea.comment').val()

    if href.indexOf('?') == -1
      href = href + '?comment=' + comment
    else
      href = href + '&comment=' + comment

    document.location.href = href

)(jQuery)
