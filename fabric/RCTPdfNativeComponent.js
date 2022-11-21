/**
 * @flow
 * @format
 */
 'use strict';

 import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
 
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
   fitPolicy: ?Int32,
   spacing: ?Int32,
   password: ?string,
   onChange: ?BubblingEventHandler<ChangeEvent>,
   singlePage: ?boolean,
 |}>;

 export default codegenNativeComponent<NativeProps>('RCTPdf');