/*
    This file is part of the WebKit open source project.
    This file has been generated by generate-bindings.pl. DO NOT MODIFY!

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include "JSWritableStreamSink.h"

#include "ActiveDOMObject.h"
#include "DOMPromiseProxy.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "IDLTypes.h"
#include "JSDOMBinding.h"
#include "JSDOMConvertAny.h"
#include "JSDOMConvertBase.h"
#include "JSDOMConvertPromise.h"
#include "JSDOMConvertStrings.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObject.h"
#include "JSDOMOperation.h"
#include "JSDOMOperationReturningPromise.h"
#include "JSDOMWrapperCache.h"
#include "ScriptExecutionContext.h"
#include "WebCoreJSClientData.h"
#include <JavaScriptCore/HeapAnalyzer.h>
#include <JavaScriptCore/JSCInlines.h>
#include <JavaScriptCore/JSDestructibleObjectHeapCellType.h>
#include <JavaScriptCore/SlotVisitorMacros.h>
#include <JavaScriptCore/SubspaceInlines.h>
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>
#include <wtf/URL.h>

namespace WebCore {
using namespace JSC;

// Functions

static JSC_DECLARE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_write);
static JSC_DECLARE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_close);
static JSC_DECLARE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_error);

class JSWritableStreamSinkPrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSWritableStreamSinkPrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSWritableStreamSinkPrototype* ptr = new (NotNull, JSC::allocateCell<JSWritableStreamSinkPrototype>(vm)) JSWritableStreamSinkPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSWritableStreamSinkPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSWritableStreamSinkPrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSWritableStreamSinkPrototype, JSWritableStreamSinkPrototype::Base);

/* Hash table for prototype */

static const HashTableValue JSWritableStreamSinkPrototypeTableValues[] = {
    { "write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsWritableStreamSinkPrototypeFunction_write, 1 } },
    { "close"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsWritableStreamSinkPrototypeFunction_close, 0 } },
    { "error"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsWritableStreamSinkPrototypeFunction_error, 1 } },
};

const ClassInfo JSWritableStreamSinkPrototype::s_info = { "WritableStreamSink"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSWritableStreamSinkPrototype) };

void JSWritableStreamSinkPrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    reifyStaticProperties(vm, JSWritableStreamSink::info(), JSWritableStreamSinkPrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSWritableStreamSink::s_info = { "WritableStreamSink"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSWritableStreamSink) };

JSWritableStreamSink::JSWritableStreamSink(Structure* structure, JSDOMGlobalObject& globalObject, Ref<WritableStreamSink>&& impl)
    : JSDOMWrapper<WritableStreamSink>(structure, globalObject, WTFMove(impl))
{
}

void JSWritableStreamSink::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    ASSERT(inherits(info()));

    // static_assert(!std::is_base_of<ActiveDOMObject, WritableStreamSink>::value, "Interface is not marked as [ActiveDOMObject] even though implementation class subclasses ActiveDOMObject.");
}

JSObject* JSWritableStreamSink::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return JSWritableStreamSinkPrototype::create(vm, &globalObject, JSWritableStreamSinkPrototype::createStructure(vm, &globalObject, globalObject.objectPrototype()));
}

JSObject* JSWritableStreamSink::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSWritableStreamSink>(vm, globalObject);
}

void JSWritableStreamSink::destroy(JSC::JSCell* cell)
{
    JSWritableStreamSink* thisObject = static_cast<JSWritableStreamSink*>(cell);
    thisObject->JSWritableStreamSink::~JSWritableStreamSink();
}

static inline JSC::EncodedJSValue jsWritableStreamSinkPrototypeFunction_writeBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperationReturningPromise<JSWritableStreamSink>::ClassParameter castedThis, Ref<DeferredPromise>&& promise)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    auto& impl = castedThis->wrapped();
    if (UNLIKELY(callFrame->argumentCount() < 1))
        return throwVMError(lexicalGlobalObject, throwScope, createNotEnoughArgumentsError(lexicalGlobalObject));
    auto* context = jsCast<JSDOMGlobalObject*>(lexicalGlobalObject)->scriptExecutionContext();
    if (UNLIKELY(!context))
        return JSValue::encode(jsUndefined());
    EnsureStillAliveScope argument0 = callFrame->uncheckedArgument(0);
    auto value = convert<IDLAny>(*lexicalGlobalObject, argument0.value());
    RETURN_IF_EXCEPTION(throwScope, encodedJSValue());
    RELEASE_AND_RETURN(throwScope, JSValue::encode(toJS<IDLPromise<IDLUndefined>>(*lexicalGlobalObject, *castedThis->globalObject(), throwScope, [&]() -> decltype(auto) { return impl.write(*context, WTFMove(value), WTFMove(promise)); })));
}

JSC_DEFINE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_write, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperationReturningPromise<JSWritableStreamSink>::call<jsWritableStreamSinkPrototypeFunction_writeBody>(*lexicalGlobalObject, *callFrame, "write");
}

static inline JSC::EncodedJSValue jsWritableStreamSinkPrototypeFunction_closeBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSWritableStreamSink>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    auto& impl = castedThis->wrapped();
    RELEASE_AND_RETURN(throwScope, JSValue::encode(toJS<IDLUndefined>(*lexicalGlobalObject, throwScope, [&]() -> decltype(auto) { return impl.close(); })));
}

JSC_DEFINE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_close, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSWritableStreamSink>::call<jsWritableStreamSinkPrototypeFunction_closeBody>(*lexicalGlobalObject, *callFrame, "close");
}

static inline JSC::EncodedJSValue jsWritableStreamSinkPrototypeFunction_errorBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSWritableStreamSink>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    auto& impl = castedThis->wrapped();
    if (UNLIKELY(callFrame->argumentCount() < 1))
        return throwVMError(lexicalGlobalObject, throwScope, createNotEnoughArgumentsError(lexicalGlobalObject));
    EnsureStillAliveScope argument0 = callFrame->uncheckedArgument(0);
    auto message = convert<IDLDOMString>(*lexicalGlobalObject, argument0.value());
    RETURN_IF_EXCEPTION(throwScope, encodedJSValue());
    RELEASE_AND_RETURN(throwScope, JSValue::encode(toJS<IDLUndefined>(*lexicalGlobalObject, throwScope, [&]() -> decltype(auto) { return impl.error(WTFMove(message)); })));
}

JSC_DEFINE_HOST_FUNCTION(jsWritableStreamSinkPrototypeFunction_error, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSWritableStreamSink>::call<jsWritableStreamSinkPrototypeFunction_errorBody>(*lexicalGlobalObject, *callFrame, "error");
}

JSC::GCClient::IsoSubspace* JSWritableStreamSink::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSWritableStreamSink, UseCustomHeapCellType::No>(
        vm,
        [](auto& spaces) { return spaces.m_clientSubspaceForWritableStreamSink.get(); },
        [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForWritableStreamSink = std::forward<decltype(space)>(space); },
        [](auto& spaces) { return spaces.m_subspaceForWritableStreamSink.get(); },
        [](auto& spaces, auto&& space) { spaces.m_subspaceForWritableStreamSink = std::forward<decltype(space)>(space); });
}

void JSWritableStreamSink::analyzeHeap(JSCell* cell, HeapAnalyzer& analyzer)
{
    auto* thisObject = jsCast<JSWritableStreamSink*>(cell);
    analyzer.setWrappedObjectForCell(cell, &thisObject->wrapped());
    if (thisObject->scriptExecutionContext())
        analyzer.setLabelForCell(cell, "url " + thisObject->scriptExecutionContext()->url().string());
    Base::analyzeHeap(cell, analyzer);
}

bool JSWritableStreamSinkOwner::isReachableFromOpaqueRoots(JSC::Handle<JSC::Unknown> handle, void*, AbstractSlotVisitor& visitor, const char** reason)
{
    UNUSED_PARAM(handle);
    UNUSED_PARAM(visitor);
    UNUSED_PARAM(reason);
    return false;
}

void JSWritableStreamSinkOwner::finalize(JSC::Handle<JSC::Unknown> handle, void* context)
{
    auto* jsWritableStreamSink = static_cast<JSWritableStreamSink*>(handle.slot()->asCell());
    auto& world = *static_cast<DOMWrapperWorld*>(context);
    uncacheWrapper(world, &jsWritableStreamSink->wrapped(), jsWritableStreamSink);
}

JSC::JSValue toJSNewlyCreated(JSC::JSGlobalObject*, JSDOMGlobalObject* globalObject, Ref<WritableStreamSink>&& impl)
{
    return createWrapper<WritableStreamSink>(globalObject, WTFMove(impl));
}

JSC::JSValue toJS(JSC::JSGlobalObject* lexicalGlobalObject, JSDOMGlobalObject* globalObject, WritableStreamSink& impl)
{
    return wrap(lexicalGlobalObject, globalObject, impl);
}

WritableStreamSink* JSWritableStreamSink::toWrapped(JSC::VM&, JSC::JSValue value)
{
    if (auto* wrapper = jsDynamicCast<JSWritableStreamSink*>(value))
        return &wrapper->wrapped();
    return nullptr;
}

}
