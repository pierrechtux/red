Red/System [
	Title:	"GTK Menu widget"
	Author: "RCqls, Nenad Rakocevic, Qingtian Xie"
	File: 	%menu.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

menu-item-key: func [
	item	[handle!]
	key		[integer!]
][
	g_object_set_qdata item menu-id as int-ptr! key
]

menu-item-key?: func [
	item		[handle!]
	return: 	[integer!]
][
	as integer! g_object_get_qdata item menu-id
]

build-menu: func [
	menu	[red-block!]
	hMenu	[handle!]
	target	[handle!]
	return:	[handle!]
	/local
		item		[handle!]
		sub-menu	[handle!]
		value		[red-value!]
		tail		[red-value!]
		next		[red-value!]
		str			[red-string!]
		w			[red-word!]
		len			[integer!]
		title	 	[c-string!]
		key		 	[c-string!]
		action	 	[integer!]
][
	if TYPE_OF(menu) <> TYPE_BLOCK [return null] 

	;; DEBUG: print ["Menu: " hMenu " with target: " target lf]
	value: block/rs-head menu
	tail:  block/rs-tail menu

	key:  ""
	;action: red-menu-action:
	while [value < tail][
		switch TYPE_OF(value) [
			TYPE_STRING [
				str: as red-string! value
				next: value + 1

				len: -1
				title: unicode/to-utf8 str :len
				
				item: gtk_menu_item_new_with_label title
				gtk_widget_show item
				
				if next < tail [
					switch TYPE_OF(next) [
						TYPE_BLOCK [
							;; DEBUG: print ["add sub-menu" lf]
							sub-menu: gtk_menu_new
							gtk_widget_show sub-menu
							build-menu as red-block! next sub-menu target
							gtk_menu_item_set_submenu item sub-menu
							value: value + 1
						]
						TYPE_WORD [
							w: as red-word! next
							menu-item-key item w/symbol
							;; DEBUG: print ["item " item " connected to " target " with key " w/symbol lf]
							gobj_signal_connect(item "activate" :menu-item-activate target)
							value: value + 1
						]
						default [0]
					]
				]
			]
			TYPE_WORD [
				w: as red-word! value
				if w/symbol = --- [
					item: gtk_separator_menu_item_new
				]
			]
			default [0]
		]
		gtk_menu_shell_append hMenu item
		value: value + 1
	]
	hMenu
]

context-menu: func [
	widget	[handle!]
	hMenu	[handle!]
][
	;; DEBUG: print ["context menu " hMenu " added to " widget lf]
	g_object_set_qdata widget menu-id hMenu
]

context-menu?: func [
	widget		[handle!]
	return: 	[handle!]
][
	g_object_get_qdata widget menu-id
]

build-context-menu: func [
	widget	[handle!]
	menu	[red-block!]
	/local
		hMenu		[handle!]
][
	;; DEBUG: print ["build menu for " widget lf]
	if TYPE_OF(menu) = TYPE_BLOCK [
		hMenu: gtk_menu_new
		;; DEBUG: print ["hMenu " hMenu lf]
		build-menu menu hMenu widget
		context-menu widget hMenu
	]
]

append-context-menu: func [
	menu	[red-block!]
	hMenu	[handle!]
	widget	[handle!]
	/local
		item 	[handle!]
][
	item: gtk_separator_menu_item_new
	gtk_widget_show item
	gtk_menu_shell_append hMenu item
	build-menu menu hMenu widget 
]

menu-bar?: func [
	spec	[red-block!]
	type	[integer!]
	return: [logic!]
	/local
		w	[red-word!]
][
	if all [
		TYPE_OF(spec) = TYPE_BLOCK
		not block/rs-tail? spec
		type = window
	][
		w: as red-word! block/rs-head spec
		return not all [
			TYPE_OF(w) = TYPE_WORD
			popup = symbol/resolve w/symbol
		]
	]
	no
]