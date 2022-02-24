#import "Core";
#import "Win32";
#import "String_Builder";
#import "Window";

#scope_file

prev_keyboard_state : [Key_Code.COUNT]bool;
keyboard_state : [Key_Code.COUNT]bool;
prev_mouse_button_states : [Mouse_Button.COUNT]bool;
mouse_button_states : [Mouse_Button.COUNT]bool;

#scope_export

is_key_down :: inline (key_code : Key_Code) -> bool #must
	#no_context
{
	return (GetAsyncKeyState (win32_key_code_to_vk (key_code)) & 0x8000) != 0;
}

is_key_pressed :: inline (key_code : Key_Code) -> bool #must
	#no_context
{
	return !prev_keyboard_state[cast (int) key_code] && is_key_down (key_code);
}

is_key_released :: inline (key_code : Key_Code) -> bool #must
	#no_context
{
	return prev_keyboard_state[cast (int) key_code] && !is_key_down (key_code);
}

is_mouse_button_down :: inline (button : Mouse_Button) -> bool #must
	#no_context
{
	return (GetAsyncKeyState (win32_mouse_button_to_vk (button)) & 0x8000) != 0;
}

is_mouse_button_pressed :: inline (button : Mouse_Button) -> bool #must
	#no_context
{
	return !prev_mouse_button_states[cast (int) button] && is_mouse_button_down (button);
}

is_mouse_button_released :: inline (button : Mouse_Button) -> bool #must
	#no_context
{
	return prev_mouse_button_states[cast (int) button] && !is_mouse_button_down (button);
}

get_mod_state :: inline () -> Mods #must
	#no_context
{
	result : Mods;
	if is_key_down (.CTRL)
		result |= .CTRL;
	else if is_key_down (.SHIFT)
		result |= .SHIFT;
	else if is_key_down (.ALT)
		result |= .ALT;

	return result;
}

init_input :: inline () -> bool
{
	// Register raw mouse device
	mouse : RAWINPUTDEVICE;
	mouse.usUsagePage = 0x01;
	mouse.usUsage     = 0x02;
	if !RegisterRawInputDevices (*mouse, 1, size_of (RAWINPUTDEVICE))
		return false;

	return true;
}

update_input_state :: inline ()
{
	memcpy (prev_keyboard_state.data, keyboard_state.data, size_of (bool) * prev_keyboard_state.count);
	for i : 0..keyboard_state.count - 1
		keyboard_state[i] = is_key_down (cast, no_check (Key_Code) i);
	memcpy (prev_mouse_button_states.data, mouse_button_states.data, size_of (bool) * prev_mouse_button_states.count);
	for i : 0..mouse_button_states.count - 1
		mouse_button_states[i] = is_mouse_button_down (cast, no_check (Mouse_Button) i);
}

win32_vk_to_key_code :: inline (vk : s32) -> Key_Code #must
	#no_context
{
	WIN32_VK_TO_KEY_CODE :: #insert -> string
	{
		builder : String_Builder;
		builder.allocator = HEAP_ALLOC;
		println_to_builder (*builder, "Key_Code.[");
		for i : 0..256
		{
			key_code := Key_Code.UNKNOWN;
			for WIN32_VK_TO_KEY_CODE_MAP
			{
				if it.vk == xx i
				{
					key_code = it.key_code;

					break;
				}
			}
			println_to_builder (*builder, "\t.%,", key_code);
		}
		println_to_builder (*builder, "];");

		return to_string (builder);
	};

	return WIN32_VK_TO_KEY_CODE[vk];
}

win32_key_code_to_vk :: inline (key_code : Key_Code) -> s32 #must
	#no_context
{
	WIN32_KEY_CODE_TO_VK :: #insert -> string
	{
		builder : String_Builder;
		builder.allocator = HEAP_ALLOC;
		println_to_builder (*builder, "s32.[");
		for i : 0..256
		{
			vk := 0;
			for WIN32_VK_TO_KEY_CODE_MAP
			{
				if it.key_code == xx i
				{
					vk = it.vk;

					break;
				}
			}
			println_to_builder (*builder, "\t%,", vk);
		}
		println_to_builder (*builder, "];");

		return to_string (builder);
	};

	return WIN32_KEY_CODE_TO_VK[cast (s64) key_code];
}

win32_vk_to_mouse_button :: inline (vk : DWORD) -> Mouse_Button #must
	#no_context
{
	if vk ==
	{
	case VK_LBUTTON;
		return .LEFT;
	case VK_RBUTTON;
		return .RIGHT;
	case VK_MBUTTON;
		return .MIDDLE;
	}

	return .UNKNOWN;
}

win32_mouse_button_to_vk :: inline (button : Mouse_Button) -> s32 #must
	#no_context
{
	if button ==
	{
	case .LEFT;
		return VK_LBUTTON;
	case .RIGHT;
		return VK_RBUTTON;
	case .MIDDLE;
		return VK_MBUTTON;
	}

	return 0;
}

#scope_file

Win32_VK_Key_Code_Pair :: struct
{
	vk : s32;
	key_code : Key_Code;
}

WIN32_VK_TO_KEY_CODE_MAP :: Win32_VK_Key_Code_Pair.[
	.{ VK_BACK, .BACKSPACE },
	.{ VK_TAB, .TAB },
	.{ VK_CLEAR, .CLEAR },
	.{ VK_RETURN, .RETURN },
	.{ VK_SHIFT, .SHIFT },
	.{ VK_CONTROL, .CTRL },
	.{ VK_MENU, .ALT },
	.{ VK_PAUSE, .PAUSE },
	.{ VK_CAPITAL, .CAPS_LOCK },
	.{ VK_ESCAPE, .ESCAPE },
	.{ VK_SPACE, .SPACE },
	.{ VK_PRIOR, .PAGE_UP },
	.{ VK_NEXT, .PAGE_DOWN },
	.{ VK_END, .END },
	.{ VK_HOME, .HOME },
	.{ VK_LEFT, .LEFT },
	.{ VK_UP, .UP },
	.{ VK_RIGHT, .RIGHT },
	.{ VK_DOWN, .DOWN },
	.{ VK_SELECT, .SELECT },
	.{ VK_PRINT, .PRINT },
	.{ VK_EXECUTE, .EXECUTE },
	.{ VK_SNAPSHOT, .PRINT_SCREEN },
	.{ VK_INSERT, .INSERT },
	.{ VK_DELETE, .DELETE },
	.{ VK_HELP, .HELP },
	.{ #char "0", .ZERO },
	.{ #char "1", .ONE },
	.{ #char "2", .TWO },
	.{ #char "3", .THREE },
	.{ #char "4", .FOUR },
	.{ #char "5", .FIVE },
	.{ #char "6", .SIX },
	.{ #char "7", .SEVEN },
	.{ #char "8", .EIGHT },
	.{ #char "9", .NINE },
	.{ #char "A", .A },
	.{ #char "B", .B },
	.{ #char "C", .C },
	.{ #char "D", .D },
	.{ #char "E", .E },
	.{ #char "F", .F },
	.{ #char "G", .G },
	.{ #char "H", .H },
	.{ #char "I", .I },
	.{ #char "J", .J },
	.{ #char "K", .K },
	.{ #char "L", .L },
	.{ #char "M", .M },
	.{ #char "N", .N },
	.{ #char "O", .O },
	.{ #char "P", .P },
	.{ #char "Q", .Q },
	.{ #char "R", .R },
	.{ #char "S", .S },
	.{ #char "T", .T },
	.{ #char "U", .U },
	.{ #char "V", .V },
	.{ #char "W", .W },
	.{ #char "X", .X },
	.{ #char "Y", .Y },
	.{ #char "Z", .Z },
	.{ VK_LWIN, .LEFT_SUPER },
	.{ VK_RWIN, .RIGHT_SUPER },
	.{ VK_APPS, .APPS },
	.{ VK_SLEEP, .SLEEP },
	.{ VK_NUMPAD0, .NUMPAD_0 },
	.{ VK_NUMPAD1, .NUMPAD_1 },
	.{ VK_NUMPAD2, .NUMPAD_2 },
	.{ VK_NUMPAD3, .NUMPAD_3 },
	.{ VK_NUMPAD4, .NUMPAD_4 },
	.{ VK_NUMPAD5, .NUMPAD_5 },
	.{ VK_NUMPAD6, .NUMPAD_6 },
	.{ VK_NUMPAD7, .NUMPAD_7 },
	.{ VK_NUMPAD8, .NUMPAD_8 },
	.{ VK_NUMPAD9, .NUMPAD_9 },
	.{ VK_MULTIPLY, .MULTIPLY },
	.{ VK_ADD, .ADD },
	.{ VK_SEPARATOR, .SEPARATOR },
	.{ VK_SUBTRACT, .SUBSTRACT },
	.{ VK_DECIMAL, .DECIMAL },
	.{ VK_DIVIDE, .DIVIDE },
	.{ VK_F1, .F1 },
	.{ VK_F2, .F2 },
	.{ VK_F3, .F3 },
	.{ VK_F4, .F4 },
	.{ VK_F5, .F5 },
	.{ VK_F6, .F6 },
	.{ VK_F7, .F7 },
	.{ VK_F8, .F8 },
	.{ VK_F9, .F9 },
	.{ VK_F10, .F10 },
	.{ VK_F11, .F11 },
	.{ VK_F12, .F12 },
	.{ VK_F13, .F13 },
	.{ VK_F14, .F14 },
	.{ VK_F15, .F15 },
	.{ VK_F16, .F16 },
	.{ VK_F17, .F17 },
	.{ VK_F18, .F18 },
	.{ VK_F19, .F19 },
	.{ VK_F20, .F20 },
	.{ VK_F21, .F21 },
	.{ VK_F22, .F22 },
	.{ VK_F23, .F23 },
	.{ VK_F24, .F24 },
	.{ VK_NUMLOCK, .NUM_LOCK },
	.{ VK_SCROLL, .SCROLL_LOCK },
	.{ VK_LSHIFT, .LEFT_SHIFT },
	.{ VK_RSHIFT, .RIGHT_SHIFT },
	.{ VK_LCONTROL, .LEFT_CTRL },
	.{ VK_RCONTROL, .RIGHT_CTRL },
	.{ VK_LMENU, .LEFT_ALT },
	.{ VK_RMENU, .RIGHT_ALT },
	.{ VK_BROWSER_BACK, .BROWSER_BACK },
	.{ VK_BROWSER_FORWARD, .BROWSER_FORWARD },
	.{ VK_BROWSER_REFRESH, .BROWSER_REFRESH },
	.{ VK_BROWSER_STOP, .BROWSER_STOP },
	.{ VK_BROWSER_SEARCH, .BROWSER_SEARCH },
	.{ VK_BROWSER_FAVORITES, .BROWSER_FAVORITES },
	.{ VK_BROWSER_HOME, .BROWSER_HOME },
	.{ VK_VOLUME_MUTE, .VOLUME_MUTE },
	.{ VK_VOLUME_DOWN, .VOLUME_DOWN },
	.{ VK_VOLUME_UP, .VOLUME_UP },
	.{ VK_MEDIA_NEXT_TRACK, .MEDIA_NEXT_TRACK },
	.{ VK_MEDIA_PREV_TRACK, .MEDIA_PREV_TRACK },
	.{ VK_MEDIA_STOP, .MEDIA_STOP },
	.{ VK_MEDIA_PLAY_PAUSE, .MEDIA_PLAY_PAUSE },
	.{ VK_LAUNCH_MAIL, .LAUNCH_MAIL },
	.{ VK_LAUNCH_MEDIA_SELECT, .LAUNCH_MEDIA_SELECT },
	.{ VK_LAUNCH_APP1, .LAUNCH_APP1 },
	.{ VK_LAUNCH_APP2, .LAUNCH_APP2 },
	.{ VK_OEM_1, .OEM_1 },
	.{ VK_OEM_PLUS, .OEM_PLUS },
	.{ VK_OEM_COMMA, .OEM_COMMA },
	.{ VK_OEM_MINUS, .OEM_MINUS },
	.{ VK_OEM_PERIOD, .OEM_PERIOD },
	.{ VK_OEM_2, .OEM_2 },
	.{ VK_OEM_3, .OEM_3 },
	.{ VK_OEM_4, .OEM_4 },
	.{ VK_OEM_5, .OEM_5 },
	.{ VK_OEM_6, .OEM_6 },
	.{ VK_OEM_7, .OEM_7 },
	.{ VK_OEM_8, .OEM_8 },
	.{ VK_OEM_102, .OEM_102 }
];
