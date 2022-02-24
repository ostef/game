#import "Core";
#import "Fmt";
#import "Win32";

Win32_Window_Context :: struct
{
	wndclass : WNDCLASSEXW;
}

#add_context using win32_window_context : *Win32_Window_Context;

Win32_Window_Data :: struct
{
	wm_char_utf16_high_surrogate : u16;
	message_queue : [..]Window_Message;
	last_retrieved_message : s64;
}

WIN32_WINDOW_CLASS_NAME :: "GameWindow";

win32_init_window_context :: inline () -> bool
{
	context.win32_window_context = new (Win32_Window_Context, HEAP_ALLOC);
	using context.win32_window_context;
	wndclass.cbSize        = size_of (WNDCLASSEXW);
	wndclass.style         = CS_DBLCLKS | CS_OWNDC;
	wndclass.lpfnWndProc   = win32_wnd_proc;
	wndclass.hInstance     = GetModuleHandleW (null);
	wndclass.lpszClassName = win32_utf8_to_wide (WIN32_WINDOW_CLASS_NAME, HEAP_ALLOC);
	if !RegisterClassExW (*wndclass)
	{
		show_error_box ("RegisterClassExW failed: %", win32_get_last_error ());

		return false;
	}

	return true;
}

show_error_box :: inline (parent_window : *Window, fmt_str : string, args : ..Any)
{
	temporary_block ();
	str := fmt (TEMP_ALLOC, fmt_str, ..args);
	MessageBoxW (
		win32_get_window_hwnd (parent_window),
		win32_utf8_to_wide (str, TEMP_ALLOC),
		win32_utf8_to_wide ("Error", TEMP_ALLOC),
		MB_ICONERROR | MB_OK
	);
}

show_error_box :: inline (fmt_str : string, args : ..Any)
{
	show_error_box (null, fmt_str, ..args);
}

create_window :: inline (
	title : string,
	x : s32,
	y : s32,
	width : s32,
	height : s32,
	flags : Window_Creation_Flags,
	parent_window : *Window = null
) -> *Window #must
{
	assert (context.win32_window_context != null, "Window context is not initialized.");

	if x == WINDOW_DEFAULT then x = CW_USEDEFAULT;
	if y == WINDOW_DEFAULT then y = CW_USEDEFAULT;
	if width  == WINDOW_DEFAULT then width  = CW_USEDEFAULT;
	if height == WINDOW_DEFAULT then height = CW_USEDEFAULT;

	style : DWORD = WS_OVERLAPPEDWINDOW;
	if flagged (flags, .VISIBLE)
		style |= WS_VISIBLE;

	if flagged (flags, .USE_CLIENT_COORDINATES)
	{
		rect : RECT;
		rect.left = x;
		rect.right = x + width;
		rect.top = y;
		rect.bottom = y + height;
		if AdjustWindowRectEx (*rect, style, 0, 0)
		{
			x = rect.left;
			y = rect.top;
			width = rect.right - rect.left;
			height = rect.bottom - rect.top;
		}
	}

	hwnd := CreateWindowExW (
		0,
		win32_utf8_to_wide (WIN32_WINDOW_CLASS_NAME, TEMP_ALLOC),
		win32_utf8_to_wide (title, TEMP_ALLOC),
		style,
		x,
		y,
		width,
		height,
		win32_get_window_hwnd (parent_window),
		null,
		GetModuleHandleW (null),
		null
	);
	data := new (Win32_Window_Data, HEAP_ALLOC);
	data.message_queue.allocator = HEAP_ALLOC;
	SetWindowLongPtrW (hwnd, GWLP_USERDATA, cast (*LONG) data);
	window := win32_get_window_from_hwnd (hwnd);

	return window;
}

destroy_window :: inline (window : *Window)
{
	DestroyWindow (win32_get_window_hwnd (window));
	// data is destroyed in the WM_DESTROY message. That way, child windows
	// that automatically get destroyed also free their user data.
}

win32_get_window_data :: inline (window : *Window) -> *Win32_Window_Data #must
	#no_context
{
	return cast (*Win32_Window_Data) GetWindowLongPtrW (win32_get_window_hwnd (window), GWLP_USERDATA);
}

win32_get_window_hwnd :: inline (window : *Window) -> HWND #must
	#no_context
{
	return cast (HWND) window;
}

win32_get_window_from_hwnd :: inline (hwnd : HWND) -> *Window #must
	#no_context
{
	return cast (*Window) hwnd;
}

swap_window_buffers :: inline (window : *Window)
{
	SwapBuffers (GetDC (win32_get_window_hwnd (window)));
}

get_window_position :: inline (window : *Window) -> x : s32, y : s32
	#no_context
{
	rect : RECT;
	GetWindowRect (win32_get_window_hwnd (window), *rect);

	return rect.left, rect.top;
}

set_window_position :: inline (window : *Window, x : s32, y : s32)
	#no_context
{
	SetWindowPos (win32_get_window_hwnd (window), null, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

get_window_size :: inline (window : *Window) -> width : s32, height : s32
	#no_context
{
	rect : RECT;
	GetWindowRect (win32_get_window_hwnd (window), *rect);

	return rect.right - rect.left, rect.bottom - rect.top;
}

get_viewport_size :: inline (window : *Window) -> width : s32, height : s32
	#no_context
{
	rect : RECT;
	GetClientRect (win32_get_window_hwnd (window), *rect);

	return rect.right - rect.left, rect.bottom - rect.top;
}

set_window_size :: inline (window : *Window, width : s32, height : s32)
	#no_context
{
	SetWindowPos (win32_get_window_hwnd (window), null, 0, 0, width, height, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
}

is_window_focused :: inline (window : *Window) -> bool #must
	#no_context
{
	return GetFocus () == win32_get_window_hwnd (window);
}

get_mouse_position :: inline (window : *Window) -> x : s32, y : s32
	#no_context
{
	result : POINT;
	GetCursorPos (*result);
	ScreenToClient (win32_get_window_hwnd (window), *result);

	return result.x, result.y;
}

set_mouse_position :: inline (window : *Window, x : s32, y : s32)
	#no_context
{
	pt : POINT;
	pt.x = x;
	pt.y = y;
	ClientToScreen (win32_get_window_hwnd (window), *pt);
	SetCursorPos (pt.x, pt.y);
}

pull_window_messages :: inline (window : *Window)
{
	data := win32_get_window_data (window);
	msg : MSG;
	while PeekMessageW (*msg, win32_get_window_hwnd (window), 0, 0, PM_REMOVE)
	{
		TranslateMessage (*msg);
		DispatchMessageW (*msg);
	}
}

get_next_window_message :: inline (window : *Window, msg : *Window_Message) -> bool
{
	data := win32_get_window_data (window);
	if data.last_retrieved_message >= data.message_queue.count
	{
		clear_array (*data.message_queue);
		data.last_retrieved_message = 0;

		return false;
	}
	<<msg = data.message_queue[data.last_retrieved_message];
	data.last_retrieved_message += 1;

	return true;
}

set_cursor_visibility :: inline (visible : bool)
	#no_context
{
	ShowCursor (xx visible);
}

show_cursor :: inline ()
	#no_context
{
	set_cursor_visibility (true);
}

hide_cursor :: inline ()
	#no_context
{
	set_cursor_visibility (false);
}

#scope_file

decompose_keystroke_lparam :: inline (lparam : LPARAM) ->
	repeat_count : s16,
	scan_code : u8,
	extended : bool,
	previous_key_state : bool,
	transition_state : bool,
	alt_down : bool,
	dialog_mode : bool,
	menu_mode : bool
	#no_context
{
	repeat_count := LOWORD (lparam);
	scan_code := cast, no_check (u8) HIWORD (lparam);
	extended := (HIWORD (lparam) & KF_EXTENDED) == KF_EXTENDED;
	previous_key_state := (HIWORD (lparam) & KF_REPEAT) == KF_REPEAT;
	transition_state := (HIWORD (lparam) & KF_UP) == KF_UP;
	alt_down := (HIWORD (lparam) & KF_ALTDOWN) == KF_ALTDOWN;
	dialog_mode := (HIWORD (lparam) & KF_DLGMODE) == KF_DLGMODE;
	menu_mode := (HIWORD (lparam) & KF_MENUMODE) == KF_MENUMODE;

	return repeat_count, scan_code, extended, previous_key_state, transition_state, alt_down, dialog_mode, menu_mode;
}

push_message :: inline (data : *Win32_Window_Data, msg : Window_Message)
{
	push_into_array (*data.message_queue, msg);
}

win32_wnd_proc :: (hwnd : HWND, msg : u32, wparam : WPARAM, lparam : LPARAM) -> LRESULT
	#c_call
{
	window := win32_get_window_from_hwnd (hwnd);
	using data := win32_get_window_data (window);
	if !data
		return DefWindowProcW (hwnd, msg, wparam, lparam);
	window_msg : Window_Message;
	window_msg.window = window;

	ctx : Context;
	fill_default_context (*ctx);
	push_context ctx
	{
		if msg ==
		{
		case WM_DESTROY;
			reset_array (*message_queue);
			free (data, HEAP_ALLOC);
			data = null;

		case WM_MOVE;
			window_msg.kind = .WINDOW_MOVED;
			window_msg.window_x = LOWORD (lparam);
			window_msg.window_y = HIWORD (lparam);
			push_message (data, window_msg);

		case WM_SIZE;
			if wparam ==
			{
			case SIZE_RESTORED;
				window_msg.kind = .WINDOW_RESIZED;
			case SIZE_MINIMIZED;
				window_msg.kind = .WINDOW_MINIMIZED;
			case SIZE_MAXIMIZED;
				window_msg.kind = .WINDOW_MAXIMIZED;
			case;
				return DefWindowProcW (hwnd, msg, wparam, lparam);
			}
			window_msg.viewport_width  = LOWORD (lparam);
			window_msg.viewport_height = HIWORD (lparam);
			push_message (data, window_msg);

		case WM_CLOSE;
			window_msg.kind = .WINDOW_CLOSED;
			push_message (data, window_msg);

		case WM_SHOWWINDOW;
			if wparam
				window_msg.kind = .WINDOW_SHOWN;
			else
				window_msg.kind = .WINDOW_HIDDEN;
			push_message (data, window_msg);

		case WM_SETFOCUS;
			window_msg.kind = .WINDOW_RECEIVED_FOCUS;
			push_message (data, window_msg);

		case WM_KILLFOCUS;
			window_msg.kind = .WINDOW_LOST_FOCUS;
			push_message (data, window_msg);

		case WM_CHAR;
			codepoint := cast (u32) wparam;
			UTF16_HI_SURROGATE  :: cast (u16) 0xd800;
			UTF16_LO_SURROGATE  :: cast (u16) 0xdc00;
			UTF16_SURROGATE_END :: cast (u16) 0xdfff;

			if codepoint >= UTF16_HI_SURROGATE && codepoint < UTF16_LO_SURROGATE
			{
				wm_char_utf16_high_surrogate = cast (u16) codepoint;
			}
			else
			{
				if codepoint >= UTF16_LO_SURROGATE && codepoint <= UTF16_SURROGATE_END
				{
					low_surrogate := cast (u16) codepoint;
					codepoint  = (wm_char_utf16_high_surrogate - UTF16_HI_SURROGATE) << 10;
					codepoint |= (low_surrogate - UTF16_HI_SURROGATE);
					codepoint += 0x10000;
				}

				window_msg.kind      = .TEXT_INPUT;
				window_msg.mods      = get_mod_state ();
				window_msg.codepoint = codepoint;
				push_message (data, window_msg);
			}

		case WM_SYSKEYDOWN; #through;
		case WM_SYSKEYUP; #through;
		case WM_KEYDOWN; #through;
		case WM_KEYUP;
			repeat_count,
			scan_code,
			extended,
			previous_key_state,
			transition_state,
			alt_down,
			dialog_mode,
			menu_mode := decompose_keystroke_lparam (lparam);

			if msg == WM_KEYUP || msg == WM_SYSKEYUP
				window_msg.kind = .KEY_RELEASED;
			else if previous_key_state
				window_msg.kind = .KEY_REPEATED;
			else
				window_msg.kind = .KEY_PRESSED;
			window_msg.mods     = get_mod_state ();
			window_msg.key_code = win32_vk_to_key_code (xx wparam);
			push_message (data, window_msg);

			if msg == WM_SYSKEYDOWN || msg == WM_SYSKEYUP
				return DefWindowProcW (hwnd, msg, wparam, lparam);

		case WM_LBUTTONDOWN; #through;
		case WM_LBUTTONUP; #through;
		case WM_LBUTTONDBLCLK; #through;
		case WM_MBUTTONDOWN; #through;
		case WM_MBUTTONUP; #through;
		case WM_MBUTTONDBLCLK; #through;
		case WM_RBUTTONDOWN; #through;
		case WM_RBUTTONUP; #through;
		case WM_RBUTTONDBLCLK;
			if msg ==
			{
			case WM_LBUTTONDOWN;
				window_msg.kind = .MOUSE_BUTTON_PRESSED;
				window_msg.mouse_button = .LEFT;
			
			case WM_LBUTTONUP;
				window_msg.kind = .MOUSE_BUTTON_RELEASED;
				window_msg.mouse_button = .LEFT;
			
			case WM_LBUTTONDBLCLK;
				window_msg.kind = .MOUSE_BUTTON_REPEATED;
				window_msg.mouse_button = .LEFT;
			
			case WM_MBUTTONDOWN;
				window_msg.kind = .MOUSE_BUTTON_PRESSED;
				window_msg.mouse_button = .MIDDLE;
			
			case WM_MBUTTONUP;
				window_msg.kind = .MOUSE_BUTTON_RELEASED;
				window_msg.mouse_button = .MIDDLE;
			
			case WM_MBUTTONDBLCLK;
				window_msg.kind = .MOUSE_BUTTON_REPEATED;
				window_msg.mouse_button = .MIDDLE;
			
			case WM_RBUTTONDOWN;
				window_msg.kind = .MOUSE_BUTTON_PRESSED;
				window_msg.mouse_button = .RIGHT;
			
			case WM_RBUTTONUP;
				window_msg.kind = .MOUSE_BUTTON_RELEASED;
				window_msg.mouse_button = .RIGHT;
			
			case WM_RBUTTONDBLCLK;
				window_msg.kind = .MOUSE_BUTTON_REPEATED;
				window_msg.mouse_button = .RIGHT;
			}
			window_msg.mods = get_mod_state ();
			window_msg.mouse_x = LOWORD (lparam);
			window_msg.mouse_y = HIWORD (lparam);
			push_message (data, window_msg);

		case WM_MOUSEHWHEEL; #through;
		case WM_MOUSEWHEEL;
			window_msg.kind = .MOUSE_WHEEL;
			window_msg.mods = get_mod_state ();
			if msg == WM_MOUSEHWHEEL
				window_msg.mouse_wheel_x = HIWORD (wparam) / 120.0;
			else
				window_msg.mouse_wheel_y = HIWORD (wparam) / 120.0;
			window_msg.mouse_x, window_msg.mouse_y = get_mouse_position (window);
			push_message (data, window_msg);

		case WM_MOUSEMOVE;
			window_msg.kind = .MOUSE_MOVED;
			window_msg.mods = get_mod_state ();
			window_msg.mouse_x = LOWORD (lparam);
			window_msg.mouse_y = HIWORD (lparam);
			push_message (data, window_msg);

		case WM_INPUT;
			size := cast (u32) size_of (RAWINPUT);
			rawinput : RAWINPUT;
			GetRawInputData (cast (HRAWINPUT) lparam, RID_INPUT, *rawinput, *size, size_of (RAWINPUTHEADER));
			if rawinput.header.dwType == RIM_TYPEMOUSE
			{
				if flagged (rawinput.data.mouse.usFlags, MOUSE_MOVE_RELATIVE) && (rawinput.data.mouse.lLastX != 0 || rawinput.data.mouse.lLastY != 0)
				{
					window_msg.kind = .RAW_MOUSE_MOVED;
					window_msg.mods = get_mod_state ();
					window_msg.mouse_delta_x = rawinput.data.mouse.lLastX;
					window_msg.mouse_delta_y = rawinput.data.mouse.lLastY;
					push_message (data, window_msg);

					return 0;
				}
			}

			return DefWindowProcW (hwnd, msg, wparam, lparam);

		case;
			return DefWindowProcW (hwnd, msg, wparam, lparam);
		}
	}

	return 0;
}

