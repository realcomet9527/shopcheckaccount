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
#include "JSCountQueuingStrategy.h"

#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMBuiltinConstructor.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObjectInlines.h"
#include "JSDOMOperation.h"
#include "JSDOMWrapperCache.h"
#include "WebCoreJSClientData.h"
#include <JavaScriptCore/FunctionPrototype.h>
#include <JavaScriptCore/JSCInlines.h>
#include <JavaScriptCore/JSDestructibleObjectHeapCellType.h>
#include <JavaScriptCore/SlotVisitorMacros.h>
#include <JavaScriptCore/SubspaceInlines.h>
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>

namespace WebCore {
using namespace JSC;

// Functions

// Attributes

static JSC_DECLARE_CUSTOM_GETTER(jsCountQueuingStrategyConstructor);

class JSCountQueuingStrategyPrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSCountQueuingStrategyPrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSCountQueuingStrategyPrototype* ptr = new (NotNull, JSC::allocateCell<JSCountQueuingStrategyPrototype>(vm)) JSCountQueuingStrategyPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSCountQueuingStrategyPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSCountQueuingStrategyPrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSCountQueuingStrategyPrototype, JSCountQueuingStrategyPrototype::Base);

using JSCountQueuingStrategyDOMConstructor = JSDOMBuiltinConstructor<JSCountQueuingStrategy>;

template<> const ClassInfo JSCountQueuingStrategyDOMConstructor::s_info = { "CountQueuingStrategy"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCountQueuingStrategyDOMConstructor) };

template<> JSValue JSCountQueuingStrategyDOMConstructor::prototypeForStructure(JSC::VM& vm, const JSDOMGlobalObject& globalObject)
{
    UNUSED_PARAM(vm);
    return globalObject.functionPrototype();
}

template<> void JSCountQueuingStrategyDOMConstructor::initializeProperties(VM& vm, JSDOMGlobalObject& globalObject)
{
    putDirect(vm, vm.propertyNames->length, jsNumber(1), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    JSString* nameString = jsNontrivialString(vm, "CountQueuingStrategy"_s);
    m_originalName.set(vm, this, nameString);
    putDirect(vm, vm.propertyNames->name, nameString, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    putDirect(vm, vm.propertyNames->prototype, JSCountQueuingStrategy::prototype(vm, globalObject), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete);
}

template<> FunctionExecutable* JSCountQueuingStrategyDOMConstructor::initializeExecutable(VM& vm)
{
    return countQueuingStrategyInitializeCountQueuingStrategyCodeGenerator(vm);
}

/* Hash table for prototype */

static const HashTableValue JSCountQueuingStrategyPrototypeTableValues[] = {
    { "constructor"_s, static_cast<unsigned>(JSC::PropertyAttribute::DontEnum), NoIntrinsic, { HashTableValue::GetterSetterType, jsCountQueuingStrategyConstructor, 0 } },
    { "highWaterMark"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::Accessor | JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinAccessorType, countQueuingStrategyHighWaterMarkCodeGenerator, 0 } },
    { "size"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, countQueuingStrategySizeCodeGenerator, 0 } }
};

const ClassInfo JSCountQueuingStrategyPrototype::s_info = { "CountQueuingStrategy"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCountQueuingStrategyPrototype) };

void JSCountQueuingStrategyPrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    reifyStaticProperties(vm, JSCountQueuingStrategy::info(), JSCountQueuingStrategyPrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSCountQueuingStrategy::s_info = { "CountQueuingStrategy"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCountQueuingStrategy) };

JSCountQueuingStrategy::JSCountQueuingStrategy(Structure* structure, JSDOMGlobalObject& globalObject)
    : JSDOMObject(structure, globalObject)
{
}

void JSCountQueuingStrategy::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    ASSERT(inherits(info()));
}

JSObject* JSCountQueuingStrategy::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return JSCountQueuingStrategyPrototype::create(vm, &globalObject, JSCountQueuingStrategyPrototype::createStructure(vm, &globalObject, globalObject.objectPrototype()));
}

JSObject* JSCountQueuingStrategy::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSCountQueuingStrategy>(vm, globalObject);
}

JSValue JSCountQueuingStrategy::getConstructor(VM& vm, const JSGlobalObject* globalObject)
{
    return getDOMConstructor<JSCountQueuingStrategyDOMConstructor, DOMConstructorID::CountQueuingStrategy>(vm, *jsCast<const JSDOMGlobalObject*>(globalObject));
}

void JSCountQueuingStrategy::destroy(JSC::JSCell* cell)
{
    JSCountQueuingStrategy* thisObject = static_cast<JSCountQueuingStrategy*>(cell);
    thisObject->JSCountQueuingStrategy::~JSCountQueuingStrategy();
}

JSC_DEFINE_CUSTOM_GETTER(jsCountQueuingStrategyConstructor, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName))
{
    VM& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto* prototype = jsDynamicCast<JSCountQueuingStrategyPrototype*>(JSValue::decode(thisValue));
    if (UNLIKELY(!prototype))
        return throwVMTypeError(lexicalGlobalObject, throwScope);
    return JSValue::encode(JSCountQueuingStrategy::getConstructor(JSC::getVM(lexicalGlobalObject), prototype->globalObject()));
}

JSC::GCClient::IsoSubspace* JSCountQueuingStrategy::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSCountQueuingStrategy, UseCustomHeapCellType::No>(
        vm,
        [](auto& spaces) { return spaces.m_clientSubspaceForCountQueuingStrategy.get(); },
        [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForCountQueuingStrategy = std::forward<decltype(space)>(space); },
        [](auto& spaces) { return spaces.m_subspaceForCountQueuingStrategy.get(); },
        [](auto& spaces, auto&& space) { spaces.m_subspaceForCountQueuingStrategy = std::forward<decltype(space)>(space); });
}

}
