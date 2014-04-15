# Allow users to delete a line from the account-contacts nested form
$(document).on 'click', 'form.new_contact a.add-line, form.edit_contact a.remove-line', (event) ->
  event.preventDefault()
  line = $(this).parents('tr.account-contact')
  line.find( 'input.delete-checkbox' ).val(1)
  line.hide()

# Allow users to add a line to the account-contacts nested form
$(document).on 'click', 'form.new_contact a.add-line, form.edit_contact a.add-line', (event) ->
  event.preventDefault()

  html = $(JSON.parse( $(this).data('html') ))
  new_id = new Date().getTime()

  # Replace the name of the select field to refer to a random, unique id number
  select  = html.find( 'select, input' )
  select.each (id, element) ->
    name    = $(element).attr( 'name' )
    name    = name.replace( /\[[\d]\]/, '[' + new_id + ']' )
    $(element).attr( 'name', name )

  # Then append the new fields to the form
  $('form.new_contact td.accounts table, form.edit_contact td.accounts table').append( html )

  html.find('.select2').select2 'width':'resolve'
