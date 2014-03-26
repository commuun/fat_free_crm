# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------

# Register the views that FatFreeCRM provides
#------------------------------------------------------------------------------

[ {:name => 'contacts_index_brief', :title => 'Brief format', :icon => 'fa-bars',
   :controllers => ['contacts'], :actions => ['index'], :template => 'contacts/index_brief'},
  {:name => 'contacts_index_long', :title => 'Long format', :icon => 'fa-list',
   :controllers => ['contacts'], :actions => ['index'], :template => 'contacts/index_long'}, # default index view
  {:name => 'contacts_index_full', :title => 'Full format', :icon => 'fa-list-alt',
   :controllers => ['contacts'], :actions => ['index'], :template => 'contacts/index_full'},
  {:name => 'contacts_show_normal', :title => 'Normal format', :icon => 'fa-list',
   :controllers => ['contacts'], :actions => ['show'], :template => nil}, # default show view

 {:name => 'accounts_index_brief', :title => 'Brief format', :icon => 'fa-bars',
  :controllers => ['accounts'], :actions => ['index'], :template => 'accounts/index_brief'}, # default
 {:name => 'accounts_index_long', :title => 'Long format', :icon => 'fa-list',
  :controllers => ['accounts'], :actions => ['index'], :template => 'accounts/index_long'}, # default
 {:name => 'accounts_show_normal', :title => 'Normal format', :icon => 'fa-list',
   :controllers => ['accounts'], :actions => ['show'], :template => nil}, # default show view

].each {|view| FatFreeCRM::ViewFactory.new(view)}
