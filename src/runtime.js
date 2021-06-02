var __create = Object.create;
var __defProp = Object.defineProperty;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;

export var __markAsModule = (target) =>
  __defProp(target, "__esModule", { value: true });
export var __commonJS = (cb, name, mod) => () => {
  return (
    mod,
    // friendly name for any errors while requiring
    (__name(cb, `export default ${name}`),
    cb((mod = { exports: {} }), mod.exports).exports,
    __name(mod, name),
    mod),
    mod.exports
  );
};

export var __reExport = (target, module, desc) => {
  if ((module && typeof module === "object") || typeof module === "function") {
    for (let key of __getOwnPropNames(module))
      if (!__hasOwnProp.call(target, key) && key !== "default")
        __defProp(target, key, {
          get: () => module[key],
          enumerable:
            !(desc = __getOwnPropDesc(module, key)) || desc.enumerable,
        });
  }
  return target;
};

export var __toModule = (module) => {
  return __reExport(
    __markAsModule(
      __defProp(
        module != null ? __create(__getProtoOf(module)) : {},
        "default",
        module && module.__esModule && "default" in module
          ? { get: () => module.default, enumerable: true }
          : { value: module, enumerable: true }
      )
    ),
    module
  );
};

export var __name = (target, name) => {
  Object.defineProperty(target, "name", {
    value: name,
    enumerable: false,
    configurable: true,
  });

  return target;
};

// browsers handles ensuring the same ESM is not loaded multiple times
export var __require = (n) => {
  return Object.prototype.hasOwnProperty.call(n, "default") &&
    Object.keys(n).length === 1
    ? n["default"]
    : n;
};

export const __esModule = true;
