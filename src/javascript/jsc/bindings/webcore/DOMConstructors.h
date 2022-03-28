#include "JavaScriptCore/JSCInlines.h"
#include "wtf/FastMalloc.h"
#include "wtf/Noncopyable.h"

#pragma once

namespace WebCore {

enum class DOMConstructorID : uint16_t {
    Touch,
    TouchEvent,
    TouchList,
    InternalSettingsGenerated,
    GPU,
    GPUAdapter,
    GPUBindGroup,
    GPUBindGroupLayout,
    GPUBuffer,
    GPUBufferUsage,
    GPUCanvasContext,
    GPUColorWrite,
    GPUCommandBuffer,
    GPUCommandEncoder,
    GPUCompilationInfo,
    GPUCompilationMessage,
    GPUComputePassEncoder,
    GPUComputePipeline,
    GPUDevice,
    GPUDeviceLostInfo,
    GPUExternalTexture,
    GPUMapMode,
    GPUOutOfMemoryError,
    GPUPipelineLayout,
    GPUQuerySet,
    GPUQueue,
    GPURenderBundle,
    GPURenderBundleEncoder,
    GPURenderPassEncoder,
    GPURenderPipeline,
    GPUSampler,
    GPUShaderModule,
    GPUShaderStage,
    GPUSupportedFeatures,
    GPUSupportedLimits,
    GPUTexture,
    GPUTextureUsage,
    GPUTextureView,
    GPUUncapturedErrorEvent,
    GPUValidationError,
    WebKitPlaybackTargetAvailabilityEvent,
    ApplePayCancelEvent,
    ApplePayCouponCodeChangedEvent,
    ApplePayError,
    ApplePayPaymentAuthorizedEvent,
    ApplePayPaymentMethodSelectedEvent,
    ApplePaySession,
    ApplePaySetup,
    ApplePaySetupFeature,
    ApplePayShippingContactSelectedEvent,
    ApplePayShippingMethodSelectedEvent,
    ApplePayValidateMerchantEvent,
    Clipboard,
    ClipboardItem,
    DOMCache,
    DOMCacheStorage,
    ContactsManager,
    BasicCredential,
    CredentialsContainer,
    MediaKeyMessageEvent,
    MediaKeySession,
    MediaKeyStatusMap,
    MediaKeySystemAccess,
    MediaKeys,
    WebKitMediaKeyMessageEvent,
    WebKitMediaKeyNeededEvent,
    WebKitMediaKeySession,
    WebKitMediaKeys,
    DOMFileSystem,
    FileSystemDirectoryEntry,
    FileSystemDirectoryReader,
    FileSystemEntry,
    FileSystemFileEntry,
    FetchHeaders,
    FetchRequest,
    FetchResponse,
    FileSystemDirectoryHandle,
    FileSystemFileHandle,
    FileSystemHandle,
    FileSystemSyncAccessHandle,
    Gamepad,
    GamepadButton,
    GamepadEvent,
    Geolocation,
    GeolocationCoordinates,
    GeolocationPosition,
    GeolocationPositionError,
    Highlight,
    HighlightRegister,
    IDBCursor,
    IDBCursorWithValue,
    IDBDatabase,
    IDBFactory,
    IDBIndex,
    IDBKeyRange,
    IDBObjectStore,
    IDBOpenDBRequest,
    IDBRequest,
    IDBTransaction,
    IDBVersionChangeEvent,
    MediaCapabilities,
    MediaControlsHost,
    BlobEvent,
    MediaRecorder,
    MediaRecorderErrorEvent,
    MediaMetadata,
    MediaSession,
    MediaSessionCoordinator,
    MediaSource,
    SourceBuffer,
    SourceBufferList,
    VideoPlaybackQuality,
    CanvasCaptureMediaStreamTrack,
    MediaDeviceInfo,
    MediaDevices,
    MediaStream,
    MediaStreamTrack,
    MediaStreamTrackEvent,
    OverconstrainedError,
    OverconstrainedErrorEvent,
    RTCCertificate,
    RTCDTMFSender,
    RTCDTMFToneChangeEvent,
    RTCDataChannel,
    RTCDataChannelEvent,
    RTCDtlsTransport,
    RTCEncodedAudioFrame,
    RTCEncodedVideoFrame,
    RTCError,
    RTCErrorEvent,
    RTCIceCandidate,
    RTCIceTransport,
    RTCPeerConnection,
    RTCPeerConnectionIceErrorEvent,
    RTCPeerConnectionIceEvent,
    RTCRtpReceiver,
    RTCRtpSFrameTransform,
    RTCRtpSFrameTransformErrorEvent,
    RTCRtpScriptTransform,
    RTCRtpScriptTransformer,
    RTCRtpSender,
    RTCRtpTransceiver,
    RTCSctpTransport,
    RTCSessionDescription,
    RTCStatsReport,
    RTCTrackEvent,
    RTCTransformEvent,
    HTMLModelElement,
    Notification,
    NotificationEvent,
    MerchantValidationEvent,
    PaymentAddress,
    PaymentMethodChangeEvent,
    PaymentRequest,
    PaymentRequestUpdateEvent,
    PaymentResponse,
    PermissionStatus,
    Permissions,
    PictureInPictureEvent,
    PictureInPictureWindow,
    PushEvent,
    PushManager,
    PushMessageData,
    PushSubscription,
    PushSubscriptionChangeEvent,
    PushSubscriptionOptions,
    RemotePlayback,
    SpeechRecognition,
    SpeechRecognitionAlternative,
    SpeechRecognitionErrorEvent,
    SpeechRecognitionEvent,
    SpeechRecognitionResult,
    SpeechRecognitionResultList,
    SpeechSynthesis,
    SpeechSynthesisErrorEvent,
    SpeechSynthesisEvent,
    SpeechSynthesisUtterance,
    SpeechSynthesisVoice,
    StorageManager,
    ByteLengthQueuingStrategy,
    CountQueuingStrategy,
    ReadableByteStreamController,
    ReadableStream,
    ReadableStreamBYOBReader,
    ReadableStreamBYOBRequest,
    ReadableStreamDefaultController,
    ReadableStreamDefaultReader,
    ReadableStreamSink,
    ReadableStreamSource,
    TransformStream,
    TransformStreamDefaultController,
    WritableStream,
    WritableStreamDefaultController,
    WritableStreamDefaultWriter,
    WritableStreamSink,
    WebLock,
    WebLockManager,
    AnalyserNode,
    AudioBuffer,
    AudioBufferSourceNode,
    AudioContext,
    AudioDestinationNode,
    AudioListener,
    AudioNode,
    AudioParam,
    AudioParamMap,
    AudioProcessingEvent,
    AudioScheduledSourceNode,
    AudioWorklet,
    AudioWorkletGlobalScope,
    AudioWorkletNode,
    AudioWorkletProcessor,
    BaseAudioContext,
    BiquadFilterNode,
    ChannelMergerNode,
    ChannelSplitterNode,
    ConstantSourceNode,
    ConvolverNode,
    DelayNode,
    DynamicsCompressorNode,
    GainNode,
    IIRFilterNode,
    MediaElementAudioSourceNode,
    MediaStreamAudioDestinationNode,
    MediaStreamAudioSourceNode,
    OfflineAudioCompletionEvent,
    OfflineAudioContext,
    OscillatorNode,
    PannerNode,
    PeriodicWave,
    ScriptProcessorNode,
    StereoPannerNode,
    WaveShaperNode,
    AuthenticatorAssertionResponse,
    AuthenticatorAttestationResponse,
    AuthenticatorResponse,
    PublicKeyCredential,
    VideoColorSpace,
    Database,
    SQLError,
    SQLResultSet,
    SQLResultSetRowList,
    SQLTransaction,
    CloseEvent,
    WebSocket,
    WebXRBoundedReferenceSpace,
    WebXRFrame,
    WebXRHand,
    WebXRInputSource,
    WebXRInputSourceArray,
    WebXRJointPose,
    WebXRJointSpace,
    WebXRLayer,
    WebXRPose,
    WebXRReferenceSpace,
    WebXRRenderState,
    WebXRRigidTransform,
    WebXRSession,
    WebXRSpace,
    WebXRSystem,
    WebXRView,
    WebXRViewerPose,
    WebXRViewport,
    WebXRWebGLLayer,
    XRInputSourceEvent,
    XRInputSourcesChangeEvent,
    XRReferenceSpaceEvent,
    XRSessionEvent,
    AnimationEffect,
    AnimationPlaybackEvent,
    AnimationTimeline,
    CSSAnimation,
    CSSTransition,
    CustomEffect,
    DocumentTimeline,
    KeyframeEffect,
    WebAnimation,
    CryptoKey,
    SubtleCrypto,
    CSSConditionRule,
    CSSCounterStyleRule,
    CSSFontFaceRule,
    CSSFontPaletteValuesRule,
    CSSGroupingRule,
    CSSImportRule,
    CSSKeyframeRule,
    CSSKeyframesRule,
    CSSLayerBlockRule,
    CSSLayerStatementRule,
    CSSMediaRule,
    CSSNamespaceRule,
    CSSPageRule,
    CSSPaintSize,
    CSSRule,
    CSSRuleList,
    CSSStyleDeclaration,
    CSSStyleRule,
    CSSStyleSheet,
    CSSSupportsRule,
    CSSUnknownRule,
    DOMCSSNamespace,
    DOMMatrix,
    DOMMatrixReadOnly,
    DeprecatedCSSOMCounter,
    DeprecatedCSSOMPrimitiveValue,
    DeprecatedCSSOMRGBColor,
    DeprecatedCSSOMRect,
    DeprecatedCSSOMValue,
    DeprecatedCSSOMValueList,
    FontFace,
    FontFaceSet,
    MediaList,
    MediaQueryList,
    MediaQueryListEvent,
    StyleMedia,
    StyleSheet,
    StyleSheetList,
    CSSKeywordValue,
    CSSNumericValue,
    CSSOMVariableReferenceValue,
    CSSStyleImageValue,
    CSSStyleValue,
    CSSUnitValue,
    CSSUnparsedValue,
    StylePropertyMap,
    StylePropertyMapReadOnly,
    CSSMathInvert,
    CSSMathMax,
    CSSMathMin,
    CSSMathNegate,
    CSSMathProduct,
    CSSMathSum,
    CSSMathValue,
    CSSNumericArray,
    CSSMatrixComponent,
    CSSPerspective,
    CSSRotate,
    CSSScale,
    CSSSkew,
    CSSSkewX,
    CSSSkewY,
    CSSTransformComponent,
    CSSTransformValue,
    CSSTranslate,
    AbortController,
    AbortSignal,
    AbstractRange,
    AnimationEvent,
    Attr,
    BeforeUnloadEvent,
    BroadcastChannel,
    CDATASection,
    CharacterData,
    ClipboardEvent,
    Comment,
    CompositionEvent,
    CustomElementRegistry,
    CustomEvent,
    DOMException,
    DOMImplementation,
    DOMPoint,
    DOMPointReadOnly,
    DOMQuad,
    DOMRect,
    DOMRectList,
    DOMRectReadOnly,
    DOMStringList,
    DOMStringMap,
    DataTransfer,
    DataTransferItem,
    DataTransferItemList,
    DeviceMotionEvent,
    DeviceOrientationEvent,
    Document,
    DocumentFragment,
    DocumentType,
    DragEvent,
    Element,
    ErrorEvent,
    Event,
    EventListener,
    EventTarget,
    FocusEvent,
    FormDataEvent,
    HashChangeEvent,
    IdleDeadline,
    InputEvent,
    KeyboardEvent,
    MessageChannel,
    MessageEvent,
    MessagePort,
    MouseEvent,
    MutationEvent,
    MutationObserver,
    MutationRecord,
    NamedNodeMap,
    Node,
    NodeFilter,
    NodeIterator,
    NodeList,
    OverflowEvent,
    PageTransitionEvent,
    PointerEvent,
    PopStateEvent,
    ProcessingInstruction,
    ProgressEvent,
    PromiseRejectionEvent,
    Range,
    SecurityPolicyViolationEvent,
    ShadowRoot,
    StaticRange,
    Text,
    TextDecoder,
    TextDecoderStream,
    TextDecoderStreamDecoder,
    TextEncoder,
    TextEncoderStream,
    TextEncoderStreamEncoder,
    TextEvent,
    TransitionEvent,
    TreeWalker,
    UIEvent,
    WheelEvent,
    XMLDocument,
    Blob,
    File,
    FileList,
    FileReader,
    FileReaderSync,
    DOMFormData,
    DOMTokenList,
    DOMURL,
    HTMLAllCollection,
    HTMLAnchorElement,
    HTMLAreaElement,
    HTMLAttachmentElement,
    HTMLAudioElement,
    HTMLAudioElementLegacyFactory,
    HTMLBRElement,
    HTMLBaseElement,
    HTMLBodyElement,
    HTMLButtonElement,
    HTMLCanvasElement,
    HTMLCollection,
    HTMLDListElement,
    HTMLDataElement,
    HTMLDataListElement,
    HTMLDetailsElement,
    HTMLDialogElement,
    HTMLDirectoryElement,
    HTMLDivElement,
    HTMLDocument,
    HTMLElement,
    HTMLEmbedElement,
    HTMLFieldSetElement,
    HTMLFontElement,
    HTMLFormControlsCollection,
    HTMLFormElement,
    HTMLFrameElement,
    HTMLFrameSetElement,
    HTMLHRElement,
    HTMLHeadElement,
    HTMLHeadingElement,
    HTMLHtmlElement,
    HTMLIFrameElement,
    HTMLImageElement,
    HTMLImageElementLegacyFactory,
    HTMLInputElement,
    HTMLLIElement,
    HTMLLabelElement,
    HTMLLegendElement,
    HTMLLinkElement,
    HTMLMapElement,
    HTMLMarqueeElement,
    HTMLMediaElement,
    HTMLMenuElement,
    HTMLMenuItemElement,
    HTMLMetaElement,
    HTMLMeterElement,
    HTMLModElement,
    HTMLOListElement,
    HTMLObjectElement,
    HTMLOptGroupElement,
    HTMLOptionElement,
    HTMLOptionElementLegacyFactory,
    HTMLOptionsCollection,
    HTMLOutputElement,
    HTMLParagraphElement,
    HTMLParamElement,
    HTMLPictureElement,
    HTMLPreElement,
    HTMLProgressElement,
    HTMLQuoteElement,
    HTMLScriptElement,
    HTMLSelectElement,
    HTMLSlotElement,
    HTMLSourceElement,
    HTMLSpanElement,
    HTMLStyleElement,
    HTMLTableCaptionElement,
    HTMLTableCellElement,
    HTMLTableColElement,
    HTMLTableElement,
    HTMLTableRowElement,
    HTMLTableSectionElement,
    HTMLTemplateElement,
    HTMLTextAreaElement,
    HTMLTimeElement,
    HTMLTitleElement,
    HTMLTrackElement,
    HTMLUListElement,
    HTMLUnknownElement,
    HTMLVideoElement,
    ImageBitmap,
    ImageData,
    MediaController,
    MediaEncryptedEvent,
    MediaError,
    OffscreenCanvas,
    RadioNodeList,
    SubmitEvent,
    TextMetrics,
    TimeRanges,
    URLSearchParams,
    ValidityState,
    WebKitMediaKeyError,
    ANGLEInstancedArrays,
    CanvasGradient,
    CanvasPattern,
    CanvasRenderingContext2D,
    EXTBlendMinMax,
    EXTColorBufferFloat,
    EXTColorBufferHalfFloat,
    EXTFloatBlend,
    EXTFragDepth,
    EXTShaderTextureLOD,
    EXTTextureCompressionRGTC,
    EXTTextureFilterAnisotropic,
    EXTsRGB,
    ImageBitmapRenderingContext,
    KHRParallelShaderCompile,
    OESElementIndexUint,
    OESFBORenderMipmap,
    OESStandardDerivatives,
    OESTextureFloat,
    OESTextureFloatLinear,
    OESTextureHalfFloat,
    OESTextureHalfFloatLinear,
    OESVertexArrayObject,
    OffscreenCanvasRenderingContext2D,
    PaintRenderingContext2D,
    Path2D,
    WebGL2RenderingContext,
    WebGLActiveInfo,
    WebGLBuffer,
    WebGLColorBufferFloat,
    WebGLCompressedTextureASTC,
    WebGLCompressedTextureATC,
    WebGLCompressedTextureETC,
    WebGLCompressedTextureETC1,
    WebGLCompressedTexturePVRTC,
    WebGLCompressedTextureS3TC,
    WebGLCompressedTextureS3TCsRGB,
    WebGLContextEvent,
    WebGLDebugRendererInfo,
    WebGLDebugShaders,
    WebGLDepthTexture,
    WebGLDrawBuffers,
    WebGLFramebuffer,
    WebGLLoseContext,
    WebGLMultiDraw,
    WebGLProgram,
    WebGLQuery,
    WebGLRenderbuffer,
    WebGLRenderingContext,
    WebGLSampler,
    WebGLShader,
    WebGLShaderPrecisionFormat,
    WebGLSync,
    WebGLTexture,
    WebGLTransformFeedback,
    WebGLUniformLocation,
    WebGLVertexArrayObject,
    WebGLVertexArrayObjectOES,
    AudioTrack,
    AudioTrackConfiguration,
    AudioTrackList,
    DataCue,
    TextTrack,
    TextTrackCue,
    TextTrackCueGeneric,
    TextTrackCueList,
    TextTrackList,
    TrackEvent,
    VTTCue,
    VTTRegion,
    VTTRegionList,
    VideoTrack,
    VideoTrackConfiguration,
    VideoTrackList,
    CommandLineAPIHost,
    InspectorAuditAccessibilityObject,
    InspectorAuditDOMObject,
    InspectorAuditResourcesObject,
    InspectorFrontendHost,
    DOMApplicationCache,
    MathMLElement,
    MathMLMathElement,
    BarProp,
    Crypto,
    DOMSelection,
    DOMWindow,
    EventSource,
    History,
    IntersectionObserver,
    IntersectionObserverEntry,
    Location,
    Navigator,
    Performance,
    PerformanceEntry,
    PerformanceMark,
    PerformanceMeasure,
    PerformanceNavigation,
    PerformanceNavigationTiming,
    PerformanceObserver,
    PerformanceObserverEntryList,
    PerformancePaintTiming,
    PerformanceResourceTiming,
    PerformanceServerTiming,
    PerformanceTiming,
    RemoteDOMWindow,
    ResizeObserver,
    ResizeObserverEntry,
    ResizeObserverSize,
    Screen,
    ShadowRealmGlobalScope,
    UndoItem,
    UndoManager,
    UserMessageHandler,
    UserMessageHandlersNamespace,
    VisualViewport,
    WebKitNamespace,
    WebKitPoint,
    WorkerNavigator,
    DOMMimeType,
    DOMMimeTypeArray,
    DOMPlugin,
    DOMPluginArray,
    Storage,
    StorageEvent,
    SVGAElement,
    SVGAltGlyphDefElement,
    SVGAltGlyphElement,
    SVGAltGlyphItemElement,
    SVGAngle,
    SVGAnimateColorElement,
    SVGAnimateElement,
    SVGAnimateMotionElement,
    SVGAnimateTransformElement,
    SVGAnimatedAngle,
    SVGAnimatedBoolean,
    SVGAnimatedEnumeration,
    SVGAnimatedInteger,
    SVGAnimatedLength,
    SVGAnimatedLengthList,
    SVGAnimatedNumber,
    SVGAnimatedNumberList,
    SVGAnimatedPreserveAspectRatio,
    SVGAnimatedRect,
    SVGAnimatedString,
    SVGAnimatedTransformList,
    SVGAnimationElement,
    SVGCircleElement,
    SVGClipPathElement,
    SVGComponentTransferFunctionElement,
    SVGCursorElement,
    SVGDefsElement,
    SVGDescElement,
    SVGElement,
    SVGEllipseElement,
    SVGFEBlendElement,
    SVGFEColorMatrixElement,
    SVGFEComponentTransferElement,
    SVGFECompositeElement,
    SVGFEConvolveMatrixElement,
    SVGFEDiffuseLightingElement,
    SVGFEDisplacementMapElement,
    SVGFEDistantLightElement,
    SVGFEDropShadowElement,
    SVGFEFloodElement,
    SVGFEFuncAElement,
    SVGFEFuncBElement,
    SVGFEFuncGElement,
    SVGFEFuncRElement,
    SVGFEGaussianBlurElement,
    SVGFEImageElement,
    SVGFEMergeElement,
    SVGFEMergeNodeElement,
    SVGFEMorphologyElement,
    SVGFEOffsetElement,
    SVGFEPointLightElement,
    SVGFESpecularLightingElement,
    SVGFESpotLightElement,
    SVGFETileElement,
    SVGFETurbulenceElement,
    SVGFilterElement,
    SVGFontElement,
    SVGFontFaceElement,
    SVGFontFaceFormatElement,
    SVGFontFaceNameElement,
    SVGFontFaceSrcElement,
    SVGFontFaceUriElement,
    SVGForeignObjectElement,
    SVGGElement,
    SVGGeometryElement,
    SVGGlyphElement,
    SVGGlyphRefElement,
    SVGGradientElement,
    SVGGraphicsElement,
    SVGHKernElement,
    SVGImageElement,
    SVGLength,
    SVGLengthList,
    SVGLineElement,
    SVGLinearGradientElement,
    SVGMPathElement,
    SVGMarkerElement,
    SVGMaskElement,
    SVGMatrix,
    SVGMetadataElement,
    SVGMissingGlyphElement,
    SVGNumber,
    SVGNumberList,
    SVGPathElement,
    SVGPathSeg,
    SVGPathSegArcAbs,
    SVGPathSegArcRel,
    SVGPathSegClosePath,
    SVGPathSegCurvetoCubicAbs,
    SVGPathSegCurvetoCubicRel,
    SVGPathSegCurvetoCubicSmoothAbs,
    SVGPathSegCurvetoCubicSmoothRel,
    SVGPathSegCurvetoQuadraticAbs,
    SVGPathSegCurvetoQuadraticRel,
    SVGPathSegCurvetoQuadraticSmoothAbs,
    SVGPathSegCurvetoQuadraticSmoothRel,
    SVGPathSegLinetoAbs,
    SVGPathSegLinetoHorizontalAbs,
    SVGPathSegLinetoHorizontalRel,
    SVGPathSegLinetoRel,
    SVGPathSegLinetoVerticalAbs,
    SVGPathSegLinetoVerticalRel,
    SVGPathSegList,
    SVGPathSegMovetoAbs,
    SVGPathSegMovetoRel,
    SVGPatternElement,
    SVGPoint,
    SVGPointList,
    SVGPolygonElement,
    SVGPolylineElement,
    SVGPreserveAspectRatio,
    SVGRadialGradientElement,
    SVGRect,
    SVGRectElement,
    SVGRenderingIntent,
    SVGSVGElement,
    SVGScriptElement,
    SVGSetElement,
    SVGStopElement,
    SVGStringList,
    SVGStyleElement,
    SVGSwitchElement,
    SVGSymbolElement,
    SVGTRefElement,
    SVGTSpanElement,
    SVGTextContentElement,
    SVGTextElement,
    SVGTextPathElement,
    SVGTextPositioningElement,
    SVGTitleElement,
    SVGTransform,
    SVGTransformList,
    SVGUnitTypes,
    SVGUseElement,
    SVGVKernElement,
    SVGViewElement,
    SVGViewSpec,
    SVGZoomEvent,
    GCObservation,
    InternalSettings,
    Internals,
    InternalsMapLike,
    InternalsSetLike,
    MallocStatistics,
    MemoryInfo,
    MockCDMFactory,
    MockContentFilterSettings,
    MockPageOverlay,
    MockPaymentCoordinator,
    ServiceWorkerInternals,
    TypeConversions,
    WebFakeXRDevice,
    WebFakeXRInputController,
    WebXRTest,
    DedicatedWorkerGlobalScope,
    Worker,
    WorkerGlobalScope,
    WorkerLocation,
    ExtendableEvent,
    ExtendableMessageEvent,
    FetchEvent,
    NavigationPreloadManager,
    ServiceWorker,
    ServiceWorkerClient,
    ServiceWorkerClients,
    ServiceWorkerContainer,
    ServiceWorkerGlobalScope,
    ServiceWorkerRegistration,
    ServiceWorkerWindowClient,
    SharedWorker,
    SharedWorkerGlobalScope,
    PaintWorkletGlobalScope,
    Worklet,
    WorkletGlobalScope,
    CustomXPathNSResolver,
    DOMParser,
    XMLHttpRequest,
    XMLHttpRequestEventTarget,
    XMLHttpRequestProgressEvent,
    XMLHttpRequestUpload,
    XMLSerializer,
    XPathEvaluator,
    XPathExpression,
    XPathNSResolver,
    XPathResult,
    XSLTProcessor,
};

static constexpr unsigned numberOfDOMConstructors = 836;

class DOMConstructors {
    WTF_MAKE_NONCOPYABLE(DOMConstructors);
    WTF_MAKE_FAST_ALLOCATED(DOMConstructors);

public:
    using ConstructorArray = std::array<JSC::WriteBarrier<JSC::JSObject>, numberOfDOMConstructors>;
    DOMConstructors() = default;
    ConstructorArray& array() { return m_array; }
    const ConstructorArray& array() const { return m_array; }

private:
    ConstructorArray m_array {};
};

} // namespace WebCore
