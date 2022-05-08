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
#include "JSAbortController.h"

#include "ActiveDOMObject.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "IDLTypes.h"
#include "JSAbortSignal.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMConstructor.h"
#include "JSDOMConvertAny.h"
#include "JSDOMConvertBase.h"
#include "JSDOMConvertInterface.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObject.h"
#include "JSDOMGlobalObjectInlines.h"
#include "JSDOMOperation.h"
#include "JSDOMWrapperCache.h"
#include "ScriptExecutionContext.h"
#include "WebCoreJSClientData.h"
#include "JavaScriptCore/FunctionPrototype.h"
#include "JavaScriptCore/HeapAnalyzer.h"

#include "JavaScriptCore/JSDestructibleObjectHeapCellType.h"
#include "JavaScriptCore/SlotVisitorMacros.h"
#include "JavaScriptCore/SubspaceInlines.h"
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>
#include <wtf/URL.h>

#include "weak_handle.h"

namespace WebCore {
using namespace JSC;

// Functions

static JSC_DECLARE_HOST_FUNCTION(jsAbortControllerPrototypeFunction_abort);

// Attributes

static JSC_DECLARE_CUSTOM_GETTER(jsAbortControllerConstructor);
static JSC_DECLARE_CUSTOM_GETTER(jsAbortController_signal);

class JSAbortControllerPrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSAbortControllerPrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSAbortControllerPrototype* ptr = new (NotNull, JSC::allocateCell<JSAbortControllerPrototype>(vm)) JSAbortControllerPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSAbortControllerPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSAbortControllerPrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSAbortControllerPrototype, JSAbortControllerPrototype::Base);

using JSAbortControllerDOMConstructor = JSDOMConstructor<JSAbortController>;

template<> EncodedJSValue JSC_HOST_CALL_ATTRIBUTES JSAbortControllerDOMConstructor::construct(JSGlobalObject* lexicalGlobalObject, CallFrame* callFrame)
{
    VM& vm = lexicalGlobalObject->vm();
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto* castedThis = jsCast<JSAbortControllerDOMConstructor*>(callFrame->jsCallee());
    ASSERT(castedThis);
    auto* context = castedThis->scriptExecutionContext();
    if (UNLIKELY(!context))
        return throwConstructorScriptExecutionContextUnavailableError(*lexicalGlobalObject, throwScope, "AbortController");
    auto object = AbortController::create(*context);
    if constexpr (IsExceptionOr<decltype(object)>)
        RETURN_IF_EXCEPTION(throwScope, {});
    static_assert(TypeOrExceptionOrUnderlyingType<decltype(object)>::isRef);
    auto jsValue = toJSNewlyCreated<IDLInterface<AbortController>>(*lexicalGlobalObject, *castedThis->globalObject(), throwScope, WTFMove(object));
    if constexpr (IsExceptionOr<decltype(object)>)
        RETURN_IF_EXCEPTION(throwScope, {});
    setSubclassStructureIfNeeded<AbortController>(lexicalGlobalObject, callFrame, asObject(jsValue));
    RETURN_IF_EXCEPTION(throwScope, {});
    return JSValue::encode(jsValue);
}
JSC_ANNOTATE_HOST_FUNCTION(JSAbortControllerDOMConstructorConstruct, JSAbortControllerDOMConstructor::construct);

template<> const ClassInfo JSAbortControllerDOMConstructor::s_info = { "AbortController"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSAbortControllerDOMConstructor) };

template<> JSValue JSAbortControllerDOMConstructor::prototypeForStructure(JSC::VM& vm, const JSDOMGlobalObject& globalObject)
{
    UNUSED_PARAM(vm);
    return globalObject.functionPrototype();
}

template<> void JSAbortControllerDOMConstructor::initializeProperties(VM& vm, JSDOMGlobalObject& globalObject)
{
    putDirect(vm, vm.propertyNames->length, jsNumber(0), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    JSString* nameString = jsNontrivialString(vm, "AbortController"_s);
    m_originalName.set(vm, this, nameString);
    putDirect(vm, vm.propertyNames->name, nameString, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    putDirect(vm, vm.propertyNames->prototype, JSAbortController::prototype(vm, globalObject), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete);
}

/* Hash table for prototype */

static const HashTableValue JSAbortControllerPrototypeTableValues[] = {
    { "constructor", static_cast<unsigned>(JSC::PropertyAttribute::DontEnum), NoIntrinsic, { (intptr_t) static_cast<PropertySlot::GetValueFunc>(jsAbortControllerConstructor), (intptr_t) static_cast<PutPropertySlot::PutValueFunc>(0) } },
    { "signal", static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { (intptr_t) static_cast<PropertySlot::GetValueFunc>(jsAbortController_signal), (intptr_t) static_cast<PutPropertySlot::PutValueFunc>(0) } },
    { "abort", static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { (intptr_t) static_cast<RawNativeFunction>(jsAbortControllerPrototypeFunction_abort), (intptr_t)(0) } },
};

const ClassInfo JSAbortControllerPrototype::s_info = { "AbortController"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSAbortControllerPrototype) };

void JSAbortControllerPrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    reifyStaticProperties(vm, JSAbortController::info(), JSAbortControllerPrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSAbortController::s_info = { "AbortController"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSAbortController) };

JSAbortController::JSAbortController(Structure* structure, JSDOMGlobalObject& globalObject, Ref<AbortController>&& impl)
    : JSDOMWrapper<AbortController>(structure, globalObject, WTFMove(impl))
{
}

void JSAbortController::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    ASSERT(inherits(info()));

    // static_assert(!std::is_base_of<ActiveDOMObject, AbortController>::value, "Interface is not marked as [ActiveDOMObject] even though implementation class subclasses ActiveDOMObject.");
}

JSObject* JSAbortController::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return JSAbortControllerPrototype::create(vm, &globalObject, JSAbortControllerPrototype::createStructure(vm, &globalObject, globalObject.objectPrototype()));
}

JSObject* JSAbortController::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSAbortController>(vm, globalObject);
}

JSValue JSAbortController::getConstructor(VM& vm, const JSGlobalObject* globalObject)
{
    return getDOMConstructor<JSAbortControllerDOMConstructor, DOMConstructorID::AbortController>(vm, *jsCast<const JSDOMGlobalObject*>(globalObject));
}

void JSAbortController::destroy(JSC::JSCell* cell)
{
    JSAbortController* thisObject = static_cast<JSAbortController*>(cell);
    thisObject->JSAbortController::~JSAbortController();
}

JSC_DEFINE_CUSTOM_GETTER(jsAbortControllerConstructor, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName))
{
    VM& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto* prototype = jsDynamicCast<JSAbortControllerPrototype*>(JSValue::decode(thisValue));
    if (UNLIKELY(!prototype))
        return throwVMTypeError(lexicalGlobalObject, throwScope);
    return JSValue::encode(JSAbortController::getConstructor(JSC::getVM(lexicalGlobalObject), prototype->globalObject()));
}

static inline JSValue jsAbortController_signalGetter(JSGlobalObject& lexicalGlobalObject, JSAbortController& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLInterface<AbortSignal>>(lexicalGlobalObject, *thisObject.globalObject(), throwScope, impl.signal())));
}

JSC_DEFINE_CUSTOM_GETTER(jsAbortController_signal, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSAbortController>::get<jsAbortController_signalGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSC::EncodedJSValue jsAbortControllerPrototypeFunction_abortBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSAbortController>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    UNUSED_PARAM(callFrame);
    auto& impl = castedThis->wrapped();
    EnsureStillAliveScope argument0 = callFrame->argument(0);
    auto reason = convert<IDLAny>(*lexicalGlobalObject, argument0.value());
    RETURN_IF_EXCEPTION(throwScope, encodedJSValue());
    RELEASE_AND_RETURN(throwScope, JSValue::encode(toJS<IDLUndefined>(*lexicalGlobalObject, throwScope, [&]() -> decltype(auto) { return impl.abort(*jsCast<JSDOMGlobalObject*>(lexicalGlobalObject), WTFMove(reason)); })));
}

JSC_DEFINE_HOST_FUNCTION(jsAbortControllerPrototypeFunction_abort, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSAbortController>::call<jsAbortControllerPrototypeFunction_abortBody>(*lexicalGlobalObject, *callFrame, "abort");
}

JSC::GCClient::IsoSubspace* JSAbortController::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSAbortController, UseCustomHeapCellType::No>(
        vm,
        [](auto& spaces) { return spaces.m_clientSubspaceForAbortController.get(); },
        [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForAbortController = WTFMove(space); },
        [](auto& spaces) { return spaces.m_subspaceForAbortController.get(); },
        [](auto& spaces, auto&& space) { spaces.m_subspaceForAbortController = WTFMove(space); });
}

template<typename Visitor>
void JSAbortController::visitChildrenImpl(JSCell* cell, Visitor& visitor)
{
    auto* thisObject = jsCast<JSAbortController*>(cell);
    ASSERT_GC_OBJECT_INHERITS(thisObject, info());
    Base::visitChildren(thisObject, visitor);
    visitor.addOpaqueRoot(WTF::getPtr(thisObject->wrapped().signal()));
}

DEFINE_VISIT_CHILDREN(JSAbortController);

void JSAbortController::analyzeHeap(JSCell* cell, HeapAnalyzer& analyzer)
{
    auto* thisObject = jsCast<JSAbortController*>(cell);
    analyzer.setWrappedObjectForCell(cell, &thisObject->wrapped());
    if (thisObject->scriptExecutionContext())
        analyzer.setLabelForCell(cell, "url " + thisObject->scriptExecutionContext()->url().string());
    Base::analyzeHeap(cell, analyzer);
}

bool JSAbortControllerOwner::isReachableFromOpaqueRoots(JSC::Handle<JSC::Unknown> handle, void*, AbstractSlotVisitor& visitor, const char** reason)
{
    UNUSED_PARAM(handle);
    UNUSED_PARAM(visitor);
    UNUSED_PARAM(reason);
    return false;
}

void JSAbortControllerOwner::finalize(JSC::Handle<JSC::Unknown> handle, void* context)
{
    auto* jsAbortController = static_cast<JSAbortController*>(handle.slot()->asCell());
    auto& world = *static_cast<DOMWrapperWorld*>(context);
    uncacheWrapper(world, &jsAbortController->wrapped(), jsAbortController);
}

JSC::JSValue toJSNewlyCreated(JSC::JSGlobalObject*, JSDOMGlobalObject* globalObject, Ref<AbortController>&& impl)
{
    return createWrapper<AbortController>(globalObject, WTFMove(impl));
}

JSC::JSValue toJS(JSC::JSGlobalObject* lexicalGlobalObject, JSDOMGlobalObject* globalObject, AbortController& impl)
{
    return wrap(lexicalGlobalObject, globalObject, impl);
}

AbortController* JSAbortController::toWrapped(JSC::VM& vm, JSC::JSValue value)
{
    if (auto* wrapper = jsDynamicCast<JSAbortController*>(value))
        return &wrapper->wrapped();
    return nullptr;
}

}
