/*
 * Copyright (c) 2015 Igalia
 * Copyright (c) 2015 Igalia S.L.
 * Copyright (c) 2015 Igalia.
 * Copyright (c) 2015, 2016 Canon Inc. All rights reserved.
 * Copyright (c) 2015, 2016, 2017 Canon Inc.
 * Copyright (c) 2016, 2020 Apple Inc. All rights reserved.
 * Copyright (c) 2022 Codeblog Corp. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

// DO NOT EDIT THIS FILE. It is automatically generated from JavaScript files for
// builtins by the script: Source/JavaScriptCore/Scripts/generate-js-builtins.py

#include "config.h"
#include "CountQueuingStrategyBuiltins.h"

#include "WebCoreJSClientData.h"
#include <JavaScriptCore/HeapInlines.h>
#include <JavaScriptCore/IdentifierInlines.h>
#include <JavaScriptCore/Intrinsic.h>
#include <JavaScriptCore/JSCJSValueInlines.h>
#include <JavaScriptCore/JSCellInlines.h>
#include <JavaScriptCore/StructureInlines.h>
#include <JavaScriptCore/VM.h>

namespace WebCore {

const JSC::ConstructAbility s_countQueuingStrategyHighWaterMarkCodeConstructAbility = JSC::ConstructAbility::CannotConstruct;
const JSC::ConstructorKind s_countQueuingStrategyHighWaterMarkCodeConstructorKind = JSC::ConstructorKind::None;
const int s_countQueuingStrategyHighWaterMarkCodeLength = 281;
static const JSC::Intrinsic s_countQueuingStrategyHighWaterMarkCodeIntrinsic = JSC::NoIntrinsic;
const char* const s_countQueuingStrategyHighWaterMarkCode =
    "(function ()\n" \
    "{\n" \
    "    \"use strict\";\n" \
    "\n" \
    "    const highWaterMark = @getByIdDirectPrivate(this, \"highWaterMark\");\n" \
    "    if (highWaterMark === @undefined)\n" \
    "        @throwTypeError(\"CountQueuingStrategy.highWaterMark getter called on incompatible |this| value.\");\n" \
    "\n" \
    "    return highWaterMark;\n" \
    "})\n" \
;

const JSC::ConstructAbility s_countQueuingStrategySizeCodeConstructAbility = JSC::ConstructAbility::CannotConstruct;
const JSC::ConstructorKind s_countQueuingStrategySizeCodeConstructorKind = JSC::ConstructorKind::None;
const int s_countQueuingStrategySizeCodeLength = 51;
static const JSC::Intrinsic s_countQueuingStrategySizeCodeIntrinsic = JSC::NoIntrinsic;
const char* const s_countQueuingStrategySizeCode =
    "(function ()\n" \
    "{\n" \
    "    \"use strict\";\n" \
    "\n" \
    "    return 1;\n" \
    "})\n" \
;

const JSC::ConstructAbility s_countQueuingStrategyInitializeCountQueuingStrategyCodeConstructAbility = JSC::ConstructAbility::CannotConstruct;
const JSC::ConstructorKind s_countQueuingStrategyInitializeCountQueuingStrategyCodeConstructorKind = JSC::ConstructorKind::None;
const int s_countQueuingStrategyInitializeCountQueuingStrategyCodeLength = 155;
static const JSC::Intrinsic s_countQueuingStrategyInitializeCountQueuingStrategyCodeIntrinsic = JSC::NoIntrinsic;
const char* const s_countQueuingStrategyInitializeCountQueuingStrategyCode =
    "(function (parameters)\n" \
    "{\n" \
    "    \"use strict\";\n" \
    "\n" \
    "    @putByIdDirectPrivate(this, \"highWaterMark\", @extractHighWaterMarkFromQueuingStrategyInit(parameters));\n" \
    "})\n" \
;


#define DEFINE_BUILTIN_GENERATOR(codeName, functionName, overriddenName, argumentCount) \
JSC::FunctionExecutable* codeName##Generator(JSC::VM& vm) \
{\
    JSVMClientData* clientData = static_cast<JSVMClientData*>(vm.clientData); \
    return clientData->builtinFunctions().countQueuingStrategyBuiltins().codeName##Executable()->link(vm, nullptr, clientData->builtinFunctions().countQueuingStrategyBuiltins().codeName##Source(), std::nullopt, s_##codeName##Intrinsic); \
}
WEBCORE_FOREACH_COUNTQUEUINGSTRATEGY_BUILTIN_CODE(DEFINE_BUILTIN_GENERATOR)
#undef DEFINE_BUILTIN_GENERATOR


} // namespace WebCore
