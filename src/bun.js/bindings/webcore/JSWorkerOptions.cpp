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
#include "JSWorkerOptions.h"

#include "JSDOMConvertEnumeration.h"
#include "JSDOMConvertStrings.h"
// #include "JSFetchRequestCredentials.h"
// #include "JSWorkerType.h"
#include <JavaScriptCore/JSCInlines.h>

namespace WebCore {
using namespace JSC;

template<> WorkerOptions convertDictionary<WorkerOptions>(JSGlobalObject& lexicalGlobalObject, JSValue value)
{
    VM& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    bool isNullOrUndefined = value.isUndefinedOrNull();
    auto* object = isNullOrUndefined ? nullptr : value.getObject();
    if (UNLIKELY(!isNullOrUndefined && !object)) {
        throwTypeError(&lexicalGlobalObject, throwScope);
        return {};
    }
    WorkerOptions result;
    // JSValue credentialsValue;
    // if (isNullOrUndefined)
    //     credentialsValue = jsUndefined();
    // else {
    //     credentialsValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "credentials"_s));
    //     RETURN_IF_EXCEPTION(throwScope, {});
    // }
    // if (!credentialsValue.isUndefined()) {
    //     result.credentials = convert<IDLEnumeration<FetchRequestCredentials>>(lexicalGlobalObject, credentialsValue);
    //     RETURN_IF_EXCEPTION(throwScope, {});
    // } else
    //     result.credentials = FetchRequestCredentials::SameOrigin;
    JSValue nameValue;
    if (isNullOrUndefined)
        nameValue = jsUndefined();
    else {
        nameValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "name"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!nameValue.isUndefined()) {
        result.name = convert<IDLDOMString>(lexicalGlobalObject, nameValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.name = emptyString();
    // JSValue typeValue;
    // if (isNullOrUndefined)
    //     typeValue = jsUndefined();
    // else {
    //     typeValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "type"_s));
    //     RETURN_IF_EXCEPTION(throwScope, { });
    // }
    // if (!typeValue.isUndefined()) {
    //     result.type = convert<IDLEnumeration<WorkerType>>(lexicalGlobalObject, typeValue);
    //     RETURN_IF_EXCEPTION(throwScope, { });
    // } else
    //     result.type = WorkerType::Classic;
    return result;
}

} // namespace WebCore
