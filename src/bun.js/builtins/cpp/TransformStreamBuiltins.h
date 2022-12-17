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

#pragma once

#include <JavaScriptCore/BuiltinUtils.h>
#include <JavaScriptCore/Identifier.h>
#include <JavaScriptCore/JSFunction.h>
#include <JavaScriptCore/UnlinkedFunctionExecutable.h>

namespace JSC {
class FunctionExecutable;
}

namespace WebCore {

/* TransformStream */
extern const char* const s_transformStreamInitializeTransformStreamCode;
extern const int s_transformStreamInitializeTransformStreamCodeLength;
extern const JSC::ConstructAbility s_transformStreamInitializeTransformStreamCodeConstructAbility;
extern const JSC::ConstructorKind s_transformStreamInitializeTransformStreamCodeConstructorKind;
extern const JSC::ImplementationVisibility s_transformStreamInitializeTransformStreamCodeImplementationVisibility;
extern const char* const s_transformStreamReadableCode;
extern const int s_transformStreamReadableCodeLength;
extern const JSC::ConstructAbility s_transformStreamReadableCodeConstructAbility;
extern const JSC::ConstructorKind s_transformStreamReadableCodeConstructorKind;
extern const JSC::ImplementationVisibility s_transformStreamReadableCodeImplementationVisibility;
extern const char* const s_transformStreamWritableCode;
extern const int s_transformStreamWritableCodeLength;
extern const JSC::ConstructAbility s_transformStreamWritableCodeConstructAbility;
extern const JSC::ConstructorKind s_transformStreamWritableCodeConstructorKind;
extern const JSC::ImplementationVisibility s_transformStreamWritableCodeImplementationVisibility;

#define WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_DATA(macro) \
    macro(initializeTransformStream, transformStreamInitializeTransformStream, 0) \
    macro(readable, transformStreamReadable, 0) \
    macro(writable, transformStreamWritable, 0) \

#define WEBCORE_BUILTIN_TRANSFORMSTREAM_INITIALIZETRANSFORMSTREAM 1
#define WEBCORE_BUILTIN_TRANSFORMSTREAM_READABLE 1
#define WEBCORE_BUILTIN_TRANSFORMSTREAM_WRITABLE 1

#define WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(macro) \
    macro(transformStreamInitializeTransformStreamCode, initializeTransformStream, ASCIILiteral(), s_transformStreamInitializeTransformStreamCodeLength) \
    macro(transformStreamReadableCode, readable, "get readable"_s, s_transformStreamReadableCodeLength) \
    macro(transformStreamWritableCode, writable, ASCIILiteral(), s_transformStreamWritableCodeLength) \

#define WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_FUNCTION_NAME(macro) \
    macro(initializeTransformStream) \
    macro(readable) \
    macro(writable) \

#define DECLARE_BUILTIN_GENERATOR(codeName, functionName, overriddenName, argumentCount) \
    JSC::FunctionExecutable* codeName##Generator(JSC::VM&);

WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(DECLARE_BUILTIN_GENERATOR)
#undef DECLARE_BUILTIN_GENERATOR

class TransformStreamBuiltinsWrapper : private JSC::WeakHandleOwner {
public:
    explicit TransformStreamBuiltinsWrapper(JSC::VM& vm)
        : m_vm(vm)
        WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_FUNCTION_NAME(INITIALIZE_BUILTIN_NAMES)
#define INITIALIZE_BUILTIN_SOURCE_MEMBERS(name, functionName, overriddenName, length) , m_##name##Source(JSC::makeSource(StringImpl::createWithoutCopying(s_##name, length), { }))
        WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(INITIALIZE_BUILTIN_SOURCE_MEMBERS)
#undef INITIALIZE_BUILTIN_SOURCE_MEMBERS
    {
    }

#define EXPOSE_BUILTIN_EXECUTABLES(name, functionName, overriddenName, length) \
    JSC::UnlinkedFunctionExecutable* name##Executable(); \
    const JSC::SourceCode& name##Source() const { return m_##name##Source; }
    WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(EXPOSE_BUILTIN_EXECUTABLES)
#undef EXPOSE_BUILTIN_EXECUTABLES

    WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_FUNCTION_NAME(DECLARE_BUILTIN_IDENTIFIER_ACCESSOR)

    void exportNames();

private:
    JSC::VM& m_vm;

    WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_FUNCTION_NAME(DECLARE_BUILTIN_NAMES)

#define DECLARE_BUILTIN_SOURCE_MEMBERS(name, functionName, overriddenName, length) \
    JSC::SourceCode m_##name##Source;\
    JSC::Weak<JSC::UnlinkedFunctionExecutable> m_##name##Executable;
    WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(DECLARE_BUILTIN_SOURCE_MEMBERS)
#undef DECLARE_BUILTIN_SOURCE_MEMBERS

};

#define DEFINE_BUILTIN_EXECUTABLES(name, functionName, overriddenName, length) \
inline JSC::UnlinkedFunctionExecutable* TransformStreamBuiltinsWrapper::name##Executable() \
{\
    if (!m_##name##Executable) {\
        JSC::Identifier executableName = functionName##PublicName();\
        if (overriddenName)\
            executableName = JSC::Identifier::fromString(m_vm, overriddenName);\
        m_##name##Executable = JSC::Weak<JSC::UnlinkedFunctionExecutable>(JSC::createBuiltinExecutable(m_vm, m_##name##Source, executableName, s_##name##ImplementationVisibility, s_##name##ConstructorKind, s_##name##ConstructAbility), this, &m_##name##Executable);\
    }\
    return m_##name##Executable.get();\
}
WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_CODE(DEFINE_BUILTIN_EXECUTABLES)
#undef DEFINE_BUILTIN_EXECUTABLES

inline void TransformStreamBuiltinsWrapper::exportNames()
{
#define EXPORT_FUNCTION_NAME(name) m_vm.propertyNames->appendExternalName(name##PublicName(), name##PrivateName());
    WEBCORE_FOREACH_TRANSFORMSTREAM_BUILTIN_FUNCTION_NAME(EXPORT_FUNCTION_NAME)
#undef EXPORT_FUNCTION_NAME
}

} // namespace WebCore
