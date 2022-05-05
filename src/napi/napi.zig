const std = @import("std");
const JSC = @import("javascript_core");
const strings = @import("strings");
const JSValue = JSC.JSValue;
const ZigString = JSC.ZigString;
const TODO_EXCEPTION: JSC.C.ExceptionRef = null;

pub const napi_env = *JSC.JSGlobalObject;
pub const napi_ref = struct_napi_ref__;
pub const napi_handle_scope = struct_napi_handle_scope__;
pub const napi_escapable_handle_scope = struct_napi_escapable_handle_scope__;
pub const napi_callback_info = struct_napi_callback_info__;
pub const napi_deferred = struct_napi_deferred__;
pub const napi_callback_scope = struct_napi_callback_scope__;
pub const napi_async_context = struct_napi_async_context__;
pub const napi_async_work = struct_napi_async_work__;
pub const napi_threadsafe_function = struct_napi_threadsafe_function__;
pub const napi_async_cleanup_hook_handle = struct_napi_async_cleanup_hook_handle__;
pub const uv_loop_s = struct_uv_loop_s;

pub const napi_value = JSC.JSValue;
pub const struct_napi_ref__ = opaque {};
pub const struct_napi_handle_scope__ = opaque {};
pub const struct_napi_escapable_handle_scope__ = opaque {};
pub const struct_napi_callback_info__ = opaque {};
pub const struct_napi_deferred__ = opaque {};

const char16_t = u16;
pub const napi_default: c_int = 0;
pub const napi_writable: c_int = 1;
pub const napi_enumerable: c_int = 2;
pub const napi_configurable: c_int = 4;
pub const napi_static: c_int = 1024;
pub const napi_default_method: c_int = 5;
pub const napi_default_jsproperty: c_int = 7;
pub const napi_property_attributes = c_uint;
pub const napi_valuetype = enum(c_uint) {
    @"undefined" = 0,
    @"null" = 1,
    @"boolean" = 2,
    @"number" = 3,
    @"string" = 4,
    @"symbol" = 5,
    @"object" = 6,
    @"function" = 7,
    @"external" = 8,
    @"bigint" = 9,
};
pub const napi_typedarray_type = enum(c_uint) {
    int8_array = 0,
    uint8_array = 1,
    uint8_clamped_array = 2,
    int16_array = 3,
    uint16_array = 4,
    int32_array = 5,
    uint32_array = 6,
    float32_array = 7,
    float64_array = 8,
    bigint64_array = 9,
    biguint64_array = 10,
};
pub const napi_status = enum(c_uint) {
    ok = 0,
    invalid_arg = 1,
    object_expected = 2,
    string_expected = 3,
    name_expected = 4,
    function_expected = 5,
    number_expected = 6,
    boolean_expected = 7,
    array_expected = 8,
    generic_failure = 9,
    pending_exception = 10,
    cancelled = 11,
    escape_called_twice = 12,
    handle_scope_mismatch = 13,
    callback_scope_mismatch = 14,
    queue_full = 15,
    closing = 16,
    bigint_expected = 17,
    date_expected = 18,
    arraybuffer_expected = 19,
    detachable_arraybuffer_expected = 20,
    would_deadlock = 21,
};
pub const napi_callback = ?fn (napi_env, napi_callback_info) callconv(.C) napi_value;
pub const napi_finalize = ?fn (napi_env, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const napi_property_descriptor = extern struct {
    utf8name: [*c]const u8,
    name: napi_value,
    method: napi_callback,
    getter: napi_callback,
    setter: napi_callback,
    value: napi_value,
    attributes: napi_property_attributes,
    data: ?*anyopaque,
};
pub const napi_extended_error_info = extern struct {
    error_message: [*c]const u8,
    engine_reserved: ?*anyopaque,
    engine_error_code: u32,
    error_code: napi_status,
};
pub const napi_key_include_prototypes: c_int = 0;
pub const napi_key_own_only: c_int = 1;
pub const napi_key_collection_mode = c_uint;
pub const napi_key_all_properties: c_int = 0;
pub const napi_key_writable: c_int = 1;
pub const napi_key_enumerable: c_int = 2;
pub const napi_key_configurable: c_int = 4;
pub const napi_key_skip_strings: c_int = 8;
pub const napi_key_skip_symbols: c_int = 16;
pub const napi_key_filter = c_uint;
pub const napi_key_keep_numbers: c_int = 0;
pub const napi_key_numbers_to_strings: c_int = 1;
pub const napi_key_conversion = c_uint;
pub const napi_type_tag = extern struct {
    lower: u64,
    upper: u64,
};
pub extern fn napi_get_last_error_info(env: napi_env, result: [*c][*c]const napi_extended_error_info) napi_status;
pub export fn napi_get_undefined(_: napi_env, result: *napi_value) napi_status {
    result.* = JSValue.jsUndefined();
    return .ok;
}
pub export fn napi_get_null(_: napi_env, result: *napi_value) napi_status {
    result.* = JSValue.jsNull();
    return .ok;
}
pub extern fn napi_get_global(env: napi_env, result: *napi_value) napi_status;
pub export fn napi_get_boolean(_: napi_env, value: bool, result: *napi_value) napi_status {
    result.* = JSValue.jsBoolean(value);
    return .ok;
}
pub export fn napi_create_object(env: napi_env, result: *napi_value) napi_status {
    result.* = JSValue.c(JSC.C.JSObjectMake(env.ref(), null, null));
    return .ok;
}
pub export fn napi_create_array(env: napi_env, result: *napi_value) napi_status {
    result.* = JSValue.c(JSC.C.JSObjectMakeArray(env.ref(), 0, null, null));
    return .ok;
}
const prefilled_undefined_args_array: [128]JSC.JSValue = brk: {
    var args: [128]JSC.JSValue = undefined;
    for (args) |_, i| {
        args[i] = JSValue.jsUndefined();
    }
    break :brk args;
};
pub export fn napi_create_array_with_length(env: napi_env, length: usize, result: *napi_value) napi_status {
    if (length < prefilled_undefined_args_array.len) {
        result.* = JSValue.c(JSC.C.JSObjectMakeArray(env.ref(), length, @ptrCast([*]const JSC.C.JSValueRef, &prefilled_undefined_args_array[0..length]), null));
        return .ok;
    }

    const allocator = JSC.VirtualMachine.vm.allocator;
    var undefined_args = allocator.alloc(JSC.C.JSValueRef, length) catch return .generic_failure;
    defer allocator.free(undefined_args);
    for (undefined_args) |_, i| {
        undefined_args[i] = JSValue.jsUndefined().asObjectRef();
    }
    result.* = JSValue.c(JSC.C.JSObjectMakeArray(env.ptr(), length, undefined_args.ptr, null));

    return .ok;
}
pub export fn napi_create_double(_: napi_env, value: f64, result: *napi_value) napi_status {
    result.* = JSValue.jsNumber(value);
    return .ok;
}
pub export fn napi_create_int32(_: napi_env, value: i32, result: *napi_value) napi_status {
    result.* = JSValue.jsNumber(value);
    return .ok;
}
pub export fn napi_create_uint32(_: napi_env, value: u32, result: *napi_value) napi_status {
    result.* = JSValue.jsNumber(value);
    return .ok;
}
pub export fn napi_create_int64(_: napi_env, value: i64, result: *napi_value) napi_status {
    result.* = JSValue.jsNumber(value);
    return .ok;
}
pub export fn napi_create_string_latin1(env: napi_env, str: [*]const u8, length: usize, result: *napi_value) napi_status {
    var len = length;
    if (NAPI_AUTO_LENGTH == length) {
        len = std.mem.sliceTo(str, 0).len;
    }
    result.* = JSC.ZigString.init(str[0..len]).toValueGC(env);
    return .ok;
}
pub export fn napi_create_string_utf8(env: napi_env, str: [*]const u8, length: usize, result: *napi_value) napi_status {
    var len = length;
    if (NAPI_AUTO_LENGTH == length) {
        len = std.mem.sliceTo(str, 0).len;
    }
    result.* = JSC.ZigString.init(str[0..len]).withEncoding().toValueGC(env);
    return .ok;
}
pub export fn napi_create_string_utf16(env: napi_env, str: [*]const char16_t, length: usize, result: *napi_value) napi_status {
    var len = length;
    if (NAPI_AUTO_LENGTH == length) {
        len = std.mem.sliceTo(str, 0).len;
    }
    result.* = JSC.ZigString.from16(str, len, env).toValueGC(env);
    return .ok;
}
pub export fn napi_create_symbol(env: napi_env, description: napi_value, result: *napi_value) napi_status {
    var string_ref = JSC.C.JSValueToStringCopy(env, description, null);
    defer JSC.C.JSStringRelease(string_ref);
    result.* = JSValue.c(JSC.C.JSValueMakeSymbol(env, string_ref));
    return .ok;
}
// const wrapped_callback_function_class_def = JSC.C.JSClassDefinition{
//     .version = 0,
//     .attributes = JSC.C.JSClassAttributes.kJSClassAttributeNone,
//     .className = "",
//     .parentClass = null,
//     .staticValues = null,
//     .staticFunctions = null,
//     .initialize = null,
//     .finalize = null,
//     .hasProperty = null,
//     .getProperty = null,
//     .setProperty = null,
//     .deleteProperty = null,
//     .getPropertyNames = null,
//     .callAsFunction = call_wrapped_callback_function,
//     .callAsConstructor = null,
//     .hasInstance = null,
//     .convertToType = null,
// };

// pub fn call_wrapped_callback_function(
//     ctx: JSC.C.JSContextRef,
//     function: JSC.C.JSObjectRef,
//     thisObject: JSC.C.JSObjectRef,
//     argumentCount: usize,
//     arguments: [*c]const JSC.C.JSValueRef,
//     exception: JSC.C.ExceptionRef,
// ) callconv(.C) JSC.C.JSValueRef {
//     var private = JSC.C.JSObjectGetPrivate(function);

// }

// pub fn getWrappedCallbackFunctionClass(env: napi_env) JSC.C.JSClassRef {}
// pub export fn napi_create_function(env: napi_env, utf8name: [*c]const u8, length: usize, cb: napi_callback, data: ?*anyopaque, result: *napi_value) napi_status {
//     //  JSC.C.JSObjectMakeFunctionWithCallback(ctx: JSContextRef, name: JSStringRef, callAsFunction: JSObjectCallAsFunctionCallback)
// }
pub export fn napi_create_error(env: napi_env, code: napi_value, msg: napi_value, result: *napi_value) napi_status {
    const system_error = JSC.SystemError{
        .code = if (!code.isEmptyOrUndefinedOrNull()) code.getZigString(env) else ZigString.Empty,
        .message = msg.getZigString(env),
    };
    result.* = system_error.toErrorInstance(env);
    return .ok;
}
pub extern fn napi_create_type_error(env: napi_env, code: napi_value, msg: napi_value, result: *napi_value) napi_status;
pub extern fn napi_create_range_error(env: napi_env, code: napi_value, msg: napi_value, result: *napi_value) napi_status;
pub extern fn napi_typeof(env: napi_env, value: napi_value, result: *napi_valuetype) napi_status;
pub export fn napi_get_value_double(_: napi_env, value: napi_value, result: *f64) napi_status {
    result.* = value.to(f64);
    return .ok;
}
pub export fn napi_get_value_int32(_: napi_env, value: napi_value, result: *i32) napi_status {
    result.* = value.to(i32);
    return .ok;
}
pub export fn napi_get_value_uint32(_: napi_env, value: napi_value, result: *u32) napi_status {
    result.* = value.to(u32);
    return .ok;
}
pub export fn napi_get_value_int64(_: napi_env, value: napi_value, result: *i64) napi_status {
    result.* = value.to(i64);
    return .ok;
}
pub export fn napi_get_value_bool(_: napi_env, value: napi_value, result: *bool) napi_status {
    result.* = value.to(bool);
    return .ok;
}
pub export fn napi_get_value_string_latin1(env: napi_env, value: napi_value, buf: [*]u8, bufsize: usize, result: *usize) napi_status {
    const zig_str = value.getZigString(env);
    if (zig_str.is16Bit()) {
        const utf16 = zig_str.utf16SliceAligned();
        const wrote = JSC.WebCore.Encoder.writeU16(utf16.ptr, utf16.len, buf, @minimum(utf16.len, bufsize), .latin1);
        if (wrote < 0) {
            return .generic_failure;
        }
        result.* = @intCast(usize, wrote);
        return .ok;
    }

    const to_copy = @minimum(zig_str.len, bufsize);
    @memcpy(buf, zig_str.slice().ptr, to_copy);
    result.* = to_copy;
    return .ok;
}
pub export fn napi_get_value_string_utf8(env: napi_env, value: napi_value, buf: [*]u8, bufsize: usize, result: *usize) napi_status {
    const zig_str = value.getZigString(env);
    if (zig_str.is16Bit()) {
        const utf16 = zig_str.utf16SliceAligned();
        const wrote = JSC.WebCore.Encoder.writeU16(utf16.ptr, utf16.len, buf, @minimum(utf16.len, bufsize), .utf8);
        if (wrote < 0) {
            return .generic_failure;
        }
        result.* = @intCast(usize, wrote);
        return .ok;
    }

    const to_copy = @minimum(zig_str.len, bufsize);
    @memcpy(buf, zig_str.slice().ptr, to_copy);
    result.* = to_copy;
    return .ok;
}
pub export fn napi_get_value_string_utf16(env: napi_env, value: napi_value, buf: [*]char16_t, bufsize: usize, result: *usize) napi_status {
    const zig_str = value.getZigString(env);
    if (!zig_str.is16Bit()) {
        const slice = zig_str.slice();
        const encode_into_result = strings.copyLatin1IntoUTF16([]char16_t, buf[0..bufsize], []const u8, slice);
        result.* = encode_into_result.written;
        return .ok;
    }

    const to_copy = @minimum(zig_str.len, bufsize);
    @memcpy(buf[0..], zig_str.utf16SliceAligned().ptr, to_copy);
    result.* = to_copy;
    return .ok;
}
pub export fn napi_coerce_to_bool(_: napi_env, value: napi_value, result: *napi_value) napi_status {
    result.* = value.to(bool);
    return .ok;
}
pub export fn napi_coerce_to_number(env: napi_env, value: napi_value, result: *napi_value) napi_status {
    result.* = JSValue.from(JSC.C.JSValueToNumber(env.ref(), value.asObjectRef(), TODO_EXCEPTION));
    return .ok;
}
pub export fn napi_coerce_to_object(env: napi_env, value: napi_value, result: *napi_value) napi_status {
    result.* = JSValue.from(JSC.C.JSValueToObject(env.ref(), value.asObjectRef(), TODO_EXCEPTION));
    return .ok;
}
// pub export fn napi_coerce_to_string(env: napi_env, value: napi_value, result: *napi_value) napi_status {

//     // result.* =  .?(env.ref(), value.asObjectRef(), TODO_EXCEPTION));
//     // return .ok;
// }
pub export fn napi_get_prototype(env: napi_env, object: napi_value, result: *napi_value) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    result.* = JSValue.from(JSC.C.JSObjectGetPrototype(env.ref(), object.asObjectRef()));
    return .ok;
}
// TODO: bind JSC::ownKeys
// pub export fn napi_get_property_names(env: napi_env, object: napi_value, result: *napi_value) napi_status {
//     if (!object.isObject()) {
//         return .object_expected;
//     }

//     result.* =
// }
pub export fn napi_set_property(env: napi_env, object: napi_value, key: napi_value, value: napi_value) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }
    var name = key.getZigString(env);
    if (name.len == 0 or value.isEmpty()) {
        return .invalid_arg;
    }
    var exception: ?JSC.C.JSValueRef = null;
    JSC.C.JSObjectSetPropertyForKey(env.ref(), object.asObjectRef(), key.asObjectRef(), value, JSC.C.JSPropertyAttributes.kJSPropertyAttributeNone, &exception);
    return if (exception == null)
        .ok
    else
        .generic_failure;
}
pub export fn napi_has_property(env: napi_env, object: napi_value, key: napi_value, result: *bool) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }
    var name = key.getZigString(env);
    var name_slice = name.toSlice(JSC.VirtualMachine.vm.allocator);
    defer name_slice.deinit();
    if (name.len == 0) {
        return .invalid_arg;
    }
    // TODO: bind hasOwnProperty
    result.* = object.get(env, &name_slice) != null;
    return .ok;
}
pub export fn napi_get_property(env: napi_env, object: napi_value, key: napi_value, result: ?*napi_value) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (!key.isString()) {
        return .invalid_arg;
    }

    var name = key.getZigString(env);
    var name_slice = name.toSlice(JSC.VirtualMachine.vm.allocator);
    defer name_slice.deinit();
    if (name.len == 0) {
        return .invalid_arg;
    }
    // TODO: DECLARE_THROW_SCOPE
    result.* = object.get(env, &name_slice);
    return .ok;
}
pub export fn napi_delete_property(env: napi_env, object: napi_value, key: napi_value, result: *bool) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (!key.isString()) {
        return .invalid_arg;
    }

    result.* = JSC.C.JSObjectDeletePropertyForKey(env, object.asObjectRef(), key.asObjectRef(), null);
    return .ok;
}
pub export fn napi_has_own_property(env: napi_env, object: napi_value, key: napi_value, result: *bool) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (!key.isString()) {
        return .invalid_arg;
    }

    result.* = JSC.C.JSObjectHasPropertyForKey(env, object.asObjectRef(), key.asObjectRef(), null);
    return .ok;
}
pub export fn napi_set_named_property(env: napi_env, object: napi_value, utf8name: [*c]const u8, value: napi_value) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (utf8name == null) {
        return .invalid_arg;
    }

    const str = std.mem.span(utf8name);
    if (str.len == 0)
        return .invalid_arg;

    var ext = JSC.C.JSStringCreateExternal(utf8name, str.len, null, null);
    defer JSC.C.JSStringRelease(ext);
    JSC.C.JSObjectSetProperty(env.ref(), object.asObjectRef, ext, value.asObjectRef(), 0, TODO_EXCEPTION);
    return .ok;
}
pub export fn napi_has_named_property(env: napi_env, object: napi_value, utf8name: [*c]const u8, result: *bool) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (utf8name == null) {
        return .invalid_arg;
    }

    const str = std.mem.span(utf8name);
    if (str.len == 0)
        return .invalid_arg;

    var ext = JSC.C.JSStringCreateExternal(utf8name, str.len, null, null);
    defer JSC.C.JSStringRelease(ext);
    result.* = JSC.C.JSObjectHasProperty(env.ref(), object.asObjectRef, ext);
    return .ok;
}
pub export fn napi_get_named_property(env: napi_env, object: napi_value, utf8name: [*c]const u8, result: *napi_value) napi_status {
    if (!object.isObject()) {
        return .object_expected;
    }

    if (utf8name == null) {
        return .invalid_arg;
    }

    const str = std.mem.span(utf8name);
    if (str.len == 0)
        return .invalid_arg;

    var ext = JSC.C.JSStringCreateExternal(utf8name, str.len, null, null);
    defer JSC.C.JSStringRelease(ext);
    result.* = JSValue.from(JSC.C.JSObjectGetProperty(env.ref(), object.asObjectRef, ext, TODO_EXCEPTION));
    return .ok;
}
pub export fn napi_set_element(env: napi_env, object: napi_value, index: c_uint, value: napi_value) napi_status {
    if (!object.jsType().isIndexable()) {
        return .array_expected;
    }
    if (value.isEmpty())
        return .invalid_arg;
    JSC.C.JSObjectSetPropertyAtIndex(env.ref(), object.asObjectRef(), index, value, TODO_EXCEPTION);
    return .ok;
}
pub export fn napi_has_element(env: napi_env, object: napi_value, index: c_uint, result: *bool) napi_status {
    if (!object.jsType().isIndexable()) {
        return .array_expected;
    }

    result.* = object.getLengthOfArray(env) > index;
    return .ok;
}
pub export fn napi_get_element(env: napi_env, object: napi_value, index: u32, result: *napi_value) napi_status {
    if (!object.jsType().isIndexable()) {
        return .array_expected;
    }

    result.* = JSC.JSObject.getIndex(object, env, index);
    return .ok;
}
pub extern fn napi_delete_element(env: napi_env, object: napi_value, index: u32, result: *bool) napi_status;
pub extern fn napi_define_properties(env: napi_env, object: napi_value, property_count: usize, properties: [*c]const napi_property_descriptor) napi_status;
pub extern fn napi_is_array(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_get_array_length(env: napi_env, value: napi_value, result: [*c]u32) napi_status;
pub extern fn napi_strict_equals(env: napi_env, lhs: napi_value, rhs: napi_value, result: *bool) napi_status;
pub extern fn napi_call_function(env: napi_env, recv: napi_value, func: napi_value, argc: usize, argv: [*c]const napi_value, result: *napi_value) napi_status;
pub extern fn napi_new_instance(env: napi_env, constructor: napi_value, argc: usize, argv: [*c]const napi_value, result: *napi_value) napi_status;
pub extern fn napi_instanceof(env: napi_env, object: napi_value, constructor: napi_value, result: *bool) napi_status;
pub extern fn napi_get_cb_info(env: napi_env, cbinfo: napi_callback_info, argc: [*c]usize, argv: *napi_value, this_arg: *napi_value, data: [*]*anyopaque) napi_status;
pub extern fn napi_get_new_target(env: napi_env, cbinfo: napi_callback_info, result: *napi_value) napi_status;
pub extern fn napi_define_class(env: napi_env, utf8name: [*c]const u8, length: usize, constructor: napi_callback, data: ?*anyopaque, property_count: usize, properties: [*c]const napi_property_descriptor, result: *napi_value) napi_status;
pub extern fn napi_wrap(env: napi_env, js_object: napi_value, native_object: ?*anyopaque, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque, result: [*c]napi_ref) napi_status;
pub extern fn napi_unwrap(env: napi_env, js_object: napi_value, result: [*]*anyopaque) napi_status;
pub extern fn napi_remove_wrap(env: napi_env, js_object: napi_value, result: [*]*anyopaque) napi_status;
pub extern fn napi_create_external(env: napi_env, data: ?*anyopaque, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_get_value_external(env: napi_env, value: napi_value, result: [*]*anyopaque) napi_status;
pub extern fn napi_create_reference(env: napi_env, value: napi_value, initial_refcount: u32, result: [*c]napi_ref) napi_status;
pub extern fn napi_delete_reference(env: napi_env, ref: napi_ref) napi_status;
pub extern fn napi_reference_ref(env: napi_env, ref: napi_ref, result: [*c]u32) napi_status;
pub extern fn napi_reference_unref(env: napi_env, ref: napi_ref, result: [*c]u32) napi_status;
pub extern fn napi_get_reference_value(env: napi_env, ref: napi_ref, result: *napi_value) napi_status;
pub extern fn napi_open_handle_scope(env: napi_env, result: [*c]napi_handle_scope) napi_status;
pub extern fn napi_close_handle_scope(env: napi_env, scope: napi_handle_scope) napi_status;
pub extern fn napi_open_escapable_handle_scope(env: napi_env, result: [*c]napi_escapable_handle_scope) napi_status;
pub extern fn napi_close_escapable_handle_scope(env: napi_env, scope: napi_escapable_handle_scope) napi_status;
pub extern fn napi_escape_handle(env: napi_env, scope: napi_escapable_handle_scope, escapee: napi_value, result: *napi_value) napi_status;
pub extern fn napi_throw(env: napi_env, @"error": napi_value) napi_status;
pub extern fn napi_throw_error(env: napi_env, code: [*c]const u8, msg: [*c]const u8) napi_status;
pub extern fn napi_throw_type_error(env: napi_env, code: [*c]const u8, msg: [*c]const u8) napi_status;
pub extern fn napi_throw_range_error(env: napi_env, code: [*c]const u8, msg: [*c]const u8) napi_status;
pub extern fn napi_is_error(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_is_exception_pending(env: napi_env, result: *bool) napi_status;
pub extern fn napi_get_and_clear_last_exception(env: napi_env, result: *napi_value) napi_status;
pub extern fn napi_is_arraybuffer(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_create_arraybuffer(env: napi_env, byte_length: usize, data: [*]*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_create_external_arraybuffer(env: napi_env, external_data: ?*anyopaque, byte_length: usize, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_get_arraybuffer_info(env: napi_env, arraybuffer: napi_value, data: [*]*anyopaque, byte_length: [*c]usize) napi_status;
pub extern fn napi_is_typedarray(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_create_typedarray(env: napi_env, @"type": napi_typedarray_type, length: usize, arraybuffer: napi_value, byte_offset: usize, result: *napi_value) napi_status;
pub extern fn napi_get_typedarray_info(env: napi_env, typedarray: napi_value, @"type": [*c]napi_typedarray_type, length: [*c]usize, data: [*]*anyopaque, arraybuffer: *napi_value, byte_offset: [*c]usize) napi_status;
pub extern fn napi_create_dataview(env: napi_env, length: usize, arraybuffer: napi_value, byte_offset: usize, result: *napi_value) napi_status;
pub extern fn napi_is_dataview(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_get_dataview_info(env: napi_env, dataview: napi_value, bytelength: [*c]usize, data: [*]*anyopaque, arraybuffer: *napi_value, byte_offset: [*c]usize) napi_status;
pub extern fn napi_get_version(env: napi_env, result: [*c]u32) napi_status;
pub extern fn napi_create_promise(env: napi_env, deferred: [*c]napi_deferred, promise: *napi_value) napi_status;
pub extern fn napi_resolve_deferred(env: napi_env, deferred: napi_deferred, resolution: napi_value) napi_status;
pub extern fn napi_reject_deferred(env: napi_env, deferred: napi_deferred, rejection: napi_value) napi_status;
pub extern fn napi_is_promise(env: napi_env, value: napi_value, is_promise: *bool) napi_status;
pub extern fn napi_run_script(env: napi_env, script: napi_value, result: *napi_value) napi_status;
pub extern fn napi_adjust_external_memory(env: napi_env, change_in_bytes: i64, adjusted_value: [*c]i64) napi_status;
pub extern fn napi_create_date(env: napi_env, time: f64, result: *napi_value) napi_status;
pub extern fn napi_is_date(env: napi_env, value: napi_value, is_date: *bool) napi_status;
pub extern fn napi_get_date_value(env: napi_env, value: napi_value, result: [*c]f64) napi_status;
pub extern fn napi_add_finalizer(env: napi_env, js_object: napi_value, native_object: ?*anyopaque, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque, result: [*c]napi_ref) napi_status;
pub extern fn napi_create_bigint_int64(env: napi_env, value: i64, result: *napi_value) napi_status;
pub extern fn napi_create_bigint_uint64(env: napi_env, value: u64, result: *napi_value) napi_status;
pub extern fn napi_create_bigint_words(env: napi_env, sign_bit: c_int, word_count: usize, words: [*c]const u64, result: *napi_value) napi_status;
pub extern fn napi_get_value_bigint_int64(env: napi_env, value: napi_value, result: [*c]i64, lossless: *bool) napi_status;
pub extern fn napi_get_value_bigint_uint64(env: napi_env, value: napi_value, result: [*c]u64, lossless: *bool) napi_status;
pub extern fn napi_get_value_bigint_words(env: napi_env, value: napi_value, sign_bit: [*c]c_int, word_count: [*c]usize, words: [*c]u64) napi_status;
pub extern fn napi_get_all_property_names(env: napi_env, object: napi_value, key_mode: napi_key_collection_mode, key_filter: napi_key_filter, key_conversion: napi_key_conversion, result: *napi_value) napi_status;
pub extern fn napi_set_instance_data(env: napi_env, data: ?*anyopaque, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque) napi_status;
pub extern fn napi_get_instance_data(env: napi_env, data: [*]*anyopaque) napi_status;
pub extern fn napi_detach_arraybuffer(env: napi_env, arraybuffer: napi_value) napi_status;
pub extern fn napi_is_detached_arraybuffer(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_type_tag_object(env: napi_env, value: napi_value, type_tag: [*c]const napi_type_tag) napi_status;
pub extern fn napi_check_object_type_tag(env: napi_env, value: napi_value, type_tag: [*c]const napi_type_tag, result: *bool) napi_status;
pub extern fn napi_object_freeze(env: napi_env, object: napi_value) napi_status;
pub extern fn napi_object_seal(env: napi_env, object: napi_value) napi_status;
pub const struct_napi_callback_scope__ = opaque {};
pub const napi_callback_scope = ?*struct_napi_callback_scope__;
pub const struct_napi_async_context__ = opaque {};
pub const napi_async_context = ?*struct_napi_async_context__;
pub const struct_napi_async_work__ = opaque {};
pub const napi_async_work = ?*struct_napi_async_work__;
pub const struct_napi_threadsafe_function__ = opaque {};
pub const napi_threadsafe_function = ?*struct_napi_threadsafe_function__;
pub const napi_tsfn_release: c_int = 0;
pub const napi_tsfn_abort: c_int = 1;
pub const napi_threadsafe_function_release_mode = c_uint;
pub const napi_tsfn_nonblocking: c_int = 0;
pub const napi_tsfn_blocking: c_int = 1;
pub const napi_threadsafe_function_call_mode = c_uint;
pub const napi_async_execute_callback = ?fn (napi_env, ?*anyopaque) callconv(.C) void;
pub const napi_async_complete_callback = ?fn (napi_env, napi_status, ?*anyopaque) callconv(.C) void;
pub const napi_threadsafe_function_call_js = ?fn (napi_env, napi_value, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const napi_node_version = extern struct {
    major: u32,
    minor: u32,
    patch: u32,
    release: [*c]const u8,
};
pub const struct_napi_async_cleanup_hook_handle__ = opaque {};
pub const napi_async_cleanup_hook_handle = ?*struct_napi_async_cleanup_hook_handle__;
pub const napi_async_cleanup_hook = ?fn (napi_async_cleanup_hook_handle, ?*anyopaque) callconv(.C) void;
pub const struct_uv_loop_s = opaque {};
pub const napi_addon_register_func = ?fn (napi_env, napi_value) callconv(.C) napi_value;
pub const struct_napi_module = extern struct {
    nm_version: c_int,
    nm_flags: c_uint,
    nm_filename: [*c]const u8,
    nm_register_func: napi_addon_register_func,
    nm_modname: [*c]const u8,
    nm_priv: ?*anyopaque,
    reserved: [4]?*anyopaque,
};
pub const napi_module = struct_napi_module;
pub extern fn napi_module_register(mod: [*c]napi_module) void;
pub extern fn napi_fatal_error(location: [*c]const u8, location_len: usize, message: [*c]const u8, message_len: usize) noreturn;
pub extern fn napi_async_init(env: napi_env, async_resource: napi_value, async_resource_name: napi_value, result: [*c]napi_async_context) napi_status;
pub extern fn napi_async_destroy(env: napi_env, async_context: napi_async_context) napi_status;
pub extern fn napi_make_callback(env: napi_env, async_context: napi_async_context, recv: napi_value, func: napi_value, argc: usize, argv: [*c]const napi_value, result: *napi_value) napi_status;
pub extern fn napi_create_buffer(env: napi_env, length: usize, data: [*]*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_create_external_buffer(env: napi_env, length: usize, data: ?*anyopaque, finalize_cb: napi_finalize, finalize_hint: ?*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_create_buffer_copy(env: napi_env, length: usize, data: ?*const anyopaque, result_data: [*]*anyopaque, result: *napi_value) napi_status;
pub extern fn napi_is_buffer(env: napi_env, value: napi_value, result: *bool) napi_status;
pub extern fn napi_get_buffer_info(env: napi_env, value: napi_value, data: [*]*anyopaque, length: [*c]usize) napi_status;
pub extern fn napi_create_async_work(env: napi_env, async_resource: napi_value, async_resource_name: napi_value, execute: napi_async_execute_callback, complete: napi_async_complete_callback, data: ?*anyopaque, result: [*c]napi_async_work) napi_status;
pub extern fn napi_delete_async_work(env: napi_env, work: napi_async_work) napi_status;
pub extern fn napi_queue_async_work(env: napi_env, work: napi_async_work) napi_status;
pub extern fn napi_cancel_async_work(env: napi_env, work: napi_async_work) napi_status;
pub extern fn napi_get_node_version(env: napi_env, version: [*c][*c]const napi_node_version) napi_status;
pub extern fn napi_get_uv_event_loop(env: napi_env, loop: [*]*struct_uv_loop_s) napi_status;
pub extern fn napi_fatal_exception(env: napi_env, err: napi_value) napi_status;
pub extern fn napi_add_env_cleanup_hook(env: napi_env, fun: ?fn (?*anyopaque) callconv(.C) void, arg: ?*anyopaque) napi_status;
pub extern fn napi_remove_env_cleanup_hook(env: napi_env, fun: ?fn (?*anyopaque) callconv(.C) void, arg: ?*anyopaque) napi_status;
pub extern fn napi_open_callback_scope(env: napi_env, resource_object: napi_value, context: napi_async_context, result: [*c]napi_callback_scope) napi_status;
pub extern fn napi_close_callback_scope(env: napi_env, scope: napi_callback_scope) napi_status;
pub extern fn napi_create_threadsafe_function(env: napi_env, func: napi_value, async_resource: napi_value, async_resource_name: napi_value, max_queue_size: usize, initial_thread_count: usize, thread_finalize_data: ?*anyopaque, thread_finalize_cb: napi_finalize, context: ?*anyopaque, call_js_cb: napi_threadsafe_function_call_js, result: [*c]napi_threadsafe_function) napi_status;
pub extern fn napi_get_threadsafe_function_context(func: napi_threadsafe_function, result: [*]*anyopaque) napi_status;
pub extern fn napi_call_threadsafe_function(func: napi_threadsafe_function, data: ?*anyopaque, is_blocking: napi_threadsafe_function_call_mode) napi_status;
pub extern fn napi_acquire_threadsafe_function(func: napi_threadsafe_function) napi_status;
pub extern fn napi_release_threadsafe_function(func: napi_threadsafe_function, mode: napi_threadsafe_function_release_mode) napi_status;
pub extern fn napi_unref_threadsafe_function(env: napi_env, func: napi_threadsafe_function) napi_status;
pub extern fn napi_ref_threadsafe_function(env: napi_env, func: napi_threadsafe_function) napi_status;
pub extern fn napi_add_async_cleanup_hook(env: napi_env, hook: napi_async_cleanup_hook, arg: ?*anyopaque, remove_handle: [*c]napi_async_cleanup_hook_handle) napi_status;
pub extern fn napi_remove_async_cleanup_hook(remove_handle: napi_async_cleanup_hook_handle) napi_status;

pub const NAPI_VERSION_EXPERIMENTAL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const NAPI_VERSION = @as(c_int, 8);
pub const NAPI_AUTO_LENGTH = std.math.maxInt(usize);
pub const SRC_NODE_API_TYPES_H_ = "";
pub const NAPI_MODULE_VERSION = @as(c_int, 1);
