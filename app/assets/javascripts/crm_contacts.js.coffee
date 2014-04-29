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


# On the "find duplicates" view, manage the merge checkboxes and buttons
$(document).on 'click', 'input.duplicate-check', (event) ->
  row       = $(this).parents('tr.duplicate-group')
  table     = $(this).parents('table.duplicates')
  siblings  = table.find( "tr.duplicate-group.group-" + row.data('group') )

  checks    = siblings.find('input.duplicate-check')
  checked   = siblings.find('input.duplicate-check:checked')
  button    = siblings.find('button.merge')

  if checked.length > 1
    button.show()
  else
    button.hide()


# Submit the to-be-merged contacts
$(document).on 'click', 'button.merge', (event) ->
  row       = $(this).parents('tr.duplicate-group')
  table     = $(this).parents('table.duplicates')
  siblings  = table.find( "tr.duplicate-group.group-" + row.data('group') )
  checked   = siblings.find('input.duplicate-check:checked')
  window.location.href = table.data('url') + '?' + checked.serialize()


# In the merge-form make it so selecting an option fills out the text field below
toggle_hidden_merge_fields = () ->
  $('table.duplicates select.merge').each (index, select) ->
    value = $(this).find('option:selected').val()
    if value == ''
      $(select).siblings('input.merge-blank').show()
      $(select).siblings('input.merge-placeholder').hide()
    else
      $(select).siblings('input.merge-blank').hide()
      $(select).siblings('input.merge-placeholder').show()
      $(this).siblings('input').val( value )

$(document).on 'ready page:load', (event) ->
  toggle_hidden_merge_fields()

$(document).on 'change', 'select.merge', (event) ->
  toggle_hidden_merge_fields()
