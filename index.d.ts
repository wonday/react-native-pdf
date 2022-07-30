/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from 'react';
import * as ReactNative from 'react-native';

export type TableContent = {
    children: TableContent[],
    mNativePtr: number,
    pageIdx: number,
    title: string,
};

export type Source = {
    uri?: string;
    headers?: {
        [key: string]: string;
    };
    cache?: boolean;
    cacheFileName?: string;
    expiration?: number;
    method?: string;
    body?: any
};

export interface PdfProps extends ReactNative.ViewProps {
    source: Source | number,
    page?: number,
    scale?: number,
    minScale?: number,
    maxScale?: number,
    horizontal?: boolean,
    spacing?: number,
    password?: string,
    renderActivityIndicator: (progress: number) => React.ReactElement,
    enableAntialiasing?: boolean,
    enableAnnotationRendering?: boolean,
    enablePaging?: boolean,
    enableRTL?: boolean,
    fitPolicy?: number,
    trustAllCerts?: boolean,
    singlePage?: boolean,
    onLoadProgress?: (percent: number) => void,
    onLoadComplete?: (numberOfPages: number, path: string, size: {height: number, width: number}, tableContents?: TableContent[]) => void,
    onPageChanged?: (page: number, numberOfPages: number) => void,
    onError?: (error: any) => void,
    onPageSingleTap?: (page: number, x: number, y: number) => void,
    onScaleChanged?: (scale: number) => void,
    onPressLink?: (url: string) => void,
    setPage: (pageNumber: number) => void;

    usePDFKit?: boolean
}

export type PdfState = {
    path: string
    isDownloaded: boolean
    progress: number
    isSupportPDFKit: number
}

export interface PdfViewProps extends ReactNative.ViewProps {
    path: string
    password?: string
    scale: number
    minScale: number
    maxScale: number
    spacing: number
    fitPolicy?: number
    horizontal?: boolean
    page: number
    currentPage: number
    singlePage: boolean
    enablePaging: boolean
    onPageSingleTap: PdfProps['onPageSingleTap']
    onScaleChanged: PdfProps['onScaleChanged']
    onLoadComplete: PdfProps['onLoadComplete']
    onError: PdfProps['onError']
    onPageChanged: PdfProps['onPageChanged']
}

export type PdfViewState = {
    pdfLoaded: boolean
    fileNo: number
    numberOfPages:number
    page: number
    currentPage: number
    pageAspectRate: number
    pdfPageSize: {width: number, height: number}
    contentContainerSize: {width: number, height: number}
    scale: number
    contentOffset: {x: number, y: number}
    newContentOffset: {x: number, y: number}
    centerContent: boolean
}

export interface PdfPageViewProps extends ReactNative.ViewProps {
    fileNo: number
    page: number
    width: number
    height: number
}

export interface PinchZoomViewProps extends ReactNative.ViewProps {
    scalable: boolean
    onScaleChanged: (scaled: {pageX: number; pageY: number; scale: number}) => void
}

export interface DoubleTapViewProps extends ReactNative.ViewProps {
    delay: number
    radius: number
    onSingleTap: PropTypes.func,
    onDoubleTap: PropTypes.func,
}
