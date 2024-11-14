/**
 * @flow
 * @format
 */
 'use strict';

 import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
 import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
 
 type ChangeEvent = $ReadOnly<{|
   message: ?string,
 |}>;
 
 export type NativeProps = $ReadOnly<{|
   ...ViewProps,
   path: ?string,
   page: ?Int32,
   scale: ?Float,
   minScale: ?Float,
   maxScale: ?Float,
   horizontal: ?boolean,
   enablePaging: ?boolean,
   enableRTL: ?boolean,
   enableAnnotationRendering: ?boolean,
   showsHorizontalScrollIndicator: ?boolean,
   showsVerticalScrollIndicator: ?boolean,
   scrollEnabled: ?boolean,
   enableAntialiasing: ?boolean,
   enableDoubleTapZoom: ?boolean,
   fitPolicy: ?Int32,
   spacing: ?Int32,
   password: ?string,
   onChange: ?BubblingEventHandler<ChangeEvent>,
   singlePage: ?boolean,
 |}>;

 interface NativeCommands {
  +setNativePage: (
    viewRef: React.ElementRef<ComponentType>,
    page: Int32,
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['setNativePage'],
});

 export default codegenNativeComponent<NativeProps>('RNPDFPdfView');
