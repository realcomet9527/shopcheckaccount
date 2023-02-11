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
#include "JSReadableStreamSource.h"

#include "ActiveDOMObject.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "IDLTypes.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMConvertAny.h"
#include "JSDOMConvertBase.h"
#include "JSDOMExceptionHandling.h"
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

static JSC_DECLARE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_start);
static JSC_DECLARE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_pull);
static JSC_DECLARE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_cancel);

// Attributes

static JSC_DECLARE_CUSTOM_GETTER(jsReadableStreamSource_controller);

class JSReadableStreamSourcePrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSReadableStreamSourcePrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSReadableStreamSourcePrototype* ptr = new (NotNull, JSC::allocateCell<JSReadableStreamSourcePrototype>(vm)) JSReadableStreamSourcePrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSReadableStreamSourcePrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSReadableStreamSourcePrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSReadableStreamSourcePrototype, JSReadableStreamSourcePrototype::Base);

/* Hash table for prototype */

static const HashTableValue JSReadableStreamSourcePrototypeTableValues[] = {
    { "controller"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { HashTableValue::GetterSetterType, jsReadableStreamSource_controller, 0 } },
    { "start"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsReadableStreamSourcePrototypeFunction_start, 1 } },
    { "pull"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsReadableStreamSourcePrototypeFunction_pull, 1 } },
    { "cancel"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsReadableStreamSourcePrototypeFunction_cancel, 1 } },
};

const ClassInfo JSReadableStreamSourcePrototype::s_info = { "ReadableStreamSource"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSReadableStreamSourcePrototype) };

void JSReadableStreamSourcePrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    // -- BUN ADDITION --
    auto clientData = WebCore::clientData(vm);
    this->putDirect(vm, clientData->builtinNames().bunNativePtrPrivateName(), jsNumber(0), JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete | 0);
    this->putDirect(vm, clientData->builtinNames().bunNativeTypePrivateName(), jsNumber(0), JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete | 0);
    // -- BUN ADDITION --

    reifyStaticProperties(vm, JSReadableStreamSource::info(), JSReadableStreamSourcePrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSReadableStreamSource::s_info = { "ReadableStreamSource"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSReadableStreamSource) };

JSReadableStreamSource::JSReadableStreamSource(Structure* structure, JSDOMGlobalObject& globalObject, Ref<ReadableStreamSource>&& impl)
    : JSDOMWrapper<ReadableStreamSource>(structure, globalObject, WTFMove(impl))
{
}

void JSReadableStreamSource::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    ASSERT(inherits(info()));

    // static_assert(!std::is_base_of<ActiveDOMObject, ReadableStreamSource>::value, "Interface is not marked as [ActiveDOMObject] even though implementation class subclasses ActiveDOMObject.");
}

JSObject* JSReadableStreamSource::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return JSReadableStreamSourcePrototype::create(vm, &globalObject, JSReadableStreamSourcePrototype::createStructure(vm, &globalObject, globalObject.objectPrototype()));
}

JSObject* JSReadableStreamSource::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSReadableStreamSource>(vm, globalObject);
}

void JSReadableStreamSource::destroy(JSC::JSCell* cell)
{
    JSReadableStreamSource* thisObject = static_cast<JSReadableStreamSource*>(cell);
    thisObject->JSReadableStreamSource::~JSReadableStreamSource();
}

static inline JSValue jsReadableStreamSource_controllerGetter(JSGlobalObject& lexicalGlobalObject, JSReadableStreamSource& thisObject)
{
    UNUSED_PARAM(lexicalGlobalObject);
    return thisObject.controller(lexicalGlobalObject);
}

JSC_DEFINE_CUSTOM_GETTER(jsReadableStreamSource_controller, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSReadableStreamSource>::get<jsReadableStreamSource_controllerGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSC::EncodedJSValue jsReadableStreamSourcePrototypeFunction_startBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperationReturningPromise<JSReadableStreamSource>::ClassParameter castedThis, Ref<DeferredPromise>&& promise)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    RELEASE_AND_RETURN(throwScope, (JSValue::encode(castedThis->start(*lexicalGlobalObject, *callFrame, WTFMove(promise)))));
}

JSC_DEFINE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_start, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperationReturningPromise<JSReadableStreamSource>::call<jsReadableStreamSourcePrototypeFunction_startBody>(*lexicalGlobalObject, *callFrame, "start");
}

static inline JSC::EncodedJSValue jsReadableStreamSourcePrototypeFunction_pullBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperationReturningPromise<JSReadableStreamSource>::ClassParameter castedThis, Ref<DeferredPromise>&& promise)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    RELEASE_AND_RETURN(throwScope, (JSValue::encode(castedThis->pull(*lexicalGlobalObject, *callFrame, WTFMove(promise)))));
}

JSC_DEFINE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_pull, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperationReturningPromise<JSReadableStreamSource>::call<jsReadableStreamSourcePrototypeFunction_pullBody>(*lexicalGlobalObject, *callFrame, "pull");
}

static inline JSC::EncodedJSValue jsReadableStreamSourcePrototypeFunction_cancelBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSReadableStreamSource>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    auto& impl = castedThis->wrapped();
    if (UNLIKELY(callFrame->argumentCount() < 1))
        return throwVMError(lexicalGlobalObject, throwScope, createNotEnoughArgumentsError(lexicalGlobalObject));
    EnsureStillAliveScope argument0 = callFrame->uncheckedArgument(0);
    auto reason = convert<IDLAny>(*lexicalGlobalObject, argument0.value());
    RETURN_IF_EXCEPTION(throwScope, encodedJSValue());
    RELEASE_AND_RETURN(throwScope, JSValue::encode(toJS<IDLUndefined>(*lexicalGlobalObject, throwScope, [&]() -> decltype(auto) { return impl.cancel(WTFMove(reason)); })));
}

JSC_DEFINE_HOST_FUNCTION(jsReadableStreamSourcePrototypeFunction_cancel, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSReadableStreamSource>::call<jsReadableStreamSourcePrototypeFunction_cancelBody>(*lexicalGlobalObject, *callFrame, "cancel");
}

JSC::GCClient::IsoSubspace* JSReadableStreamSource::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSReadableStreamSource, UseCustomHeapCellType::No>(
        vm,
        [](auto& spaces) { return spaces.m_clientSubspaceForReadableStreamSource.get(); },
        [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForReadableStreamSource = std::forward<decltype(space)>(space); },
        [](auto& spaces) { return spaces.m_subspaceForReadableStreamSource.get(); },
        [](auto& spaces, auto&& space) { spaces.m_subspaceForReadableStreamSource = std::forward<decltype(space)>(space); });
}

template<typename Visitor>
void JSReadableStreamSource::visitChildrenImpl(JSCell* cell, Visitor& visitor)
{
    auto* thisObject = jsCast<JSReadableStreamSource*>(cell);
    ASSERT_GC_OBJECT_INHERITS(thisObject, info());
    Base::visitChildren(thisObject, visitor);
    visitor.append(thisObject->m_controller);
}

DEFINE_VISIT_CHILDREN(JSReadableStreamSource);

void JSReadableStreamSource::analyzeHeap(JSCell* cell, HeapAnalyzer& analyzer)
{
    auto* thisObject = jsCast<JSReadableStreamSource*>(cell);
    analyzer.setWrappedObjectForCell(cell, &thisObject->wrapped());
    if (thisObject->scriptExecutionContext())
        analyzer.setLabelForCell(cell, "url " + thisObject->scriptExecutionContext()->url().string());
    Base::analyzeHeap(cell, analyzer);
}

bool JSReadableStreamSourceOwner::isReachableFromOpaqueRoots(JSC::Handle<JSC::Unknown> handle, void*, AbstractSlotVisitor& visitor, const char** reason)
{
    UNUSED_PARAM(handle);
    UNUSED_PARAM(visitor);
    UNUSED_PARAM(reason);
    return false;
}

void JSReadableStreamSourceOwner::finalize(JSC::Handle<JSC::Unknown> handle, void* context)
{
    auto* jsReadableStreamSource = static_cast<JSReadableStreamSource*>(handle.slot()->asCell());
    auto& world = *static_cast<DOMWrapperWorld*>(context);
    uncacheWrapper(world, &jsReadableStreamSource->wrapped(), jsReadableStreamSource);
}

JSC::JSValue toJSNewlyCreated(JSC::JSGlobalObject*, JSDOMGlobalObject* globalObject, Ref<ReadableStreamSource>&& impl)
{
    return createWrapper<ReadableStreamSource>(globalObject, WTFMove(impl));
}

JSC::JSValue toJS(JSC::JSGlobalObject* lexicalGlobalObject, JSDOMGlobalObject* globalObject, ReadableStreamSource& impl)
{
    return wrap(lexicalGlobalObject, globalObject, impl);
}

ReadableStreamSource* JSReadableStreamSource::toWrapped(JSC::VM&, JSC::JSValue value)
{
    if (auto* wrapper = jsDynamicCast<JSReadableStreamSource*>(value))
        return &wrapper->wrapped();
    return nullptr;
}

}
