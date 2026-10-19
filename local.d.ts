import * as React from 'react';
import type {PdfProps, PdfRef} from './index';

export type {TableContent, PdfError, PdfRef, TextSelectionChangeEvent} from './index';

export type LocalPdfSource = {
    // An existing file:// URI or absolute path. The caller owns the file's lifetime.
    uri: string;
};

export interface LocalPdfProps extends Omit<PdfProps, 'source' | 'trustAllCerts' | 'transformFile' | 'onLoadProgress'> {
    source: LocalPdfSource;
}

declare const LocalPdf: React.ForwardRefExoticComponent<LocalPdfProps & React.RefAttributes<PdfRef>>;

export default LocalPdf;
