/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from 'react';
import * as ReactNative from 'react-native';

interface Props {
    style?: ReactNative.ViewStyle,
    source: object,
    page?: number,
    scale?: number,
    horizontal?: boolean,
    spacing?: number,
    password?: string,
    activityIndicator?: any,
    enableAntialiasing: boolean,
    fitPolicy?: number,
    onLoadProgress?: (percent: number)=> void,
    onLoadComplete?: (pageCount: number) => void,
    onPageChanged?: (page: number, totalPage: number) => void,
    onError?: (error: string) => void,
    onPagePress?: (page:number) =>void,
    onScale?: (scale:number) =>void,
}

declare class Pdf extends React.Component<Props, any> {
}

export default Pdf;
