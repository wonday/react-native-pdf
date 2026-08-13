/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { useEffect, useRef, useState } from 'react';
import {
  StyleSheet,
  TouchableHighlight,
  View,
  Text,
  Platform,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import Pdf, { type PdfRef } from 'react-native-pdf';

interface PDFHeaderProps {
  page: number;
  scale: number;
  numberOfPages: number;
  horizontal: boolean;
  showsVerticalScrollIndicator: boolean;
  directionalLockEnabled: boolean;
  onPrePage: () => void;
  onNextPage: () => void;
  onZoomOut: () => void;
  onZoomIn: () => void;
  onSwitchHorizontal: () => void;
  onToggleScrollbars: () => void;
  onToggleDirectionalLock: () => void;
}

const createWidthStyles = (width: number) =>
  StyleSheet.create({
    pdfContainer: {
      flex: 1,
      width,
    },
  });

const PDFHeader = ({
  page,
  scale,
  numberOfPages,
  horizontal,
  showsVerticalScrollIndicator,
  directionalLockEnabled,
  onPrePage,
  onNextPage,
  onZoomOut,
  onZoomIn,
  onSwitchHorizontal,
  onToggleScrollbars,
  onToggleDirectionalLock,
}: PDFHeaderProps) => (
  <>
    <View style={styles.row}>
      <TouchableHighlight
        disabled={page === 1}
        style={page === 1 ? styles.btnDisable : styles.btn}
        onPress={onPrePage}
      >
        <Text style={styles.btnText}>{'-'}</Text>
      </TouchableHighlight>
      <View style={styles.btnText}>
        <Text style={styles.btnText}>Page</Text>
      </View>
      <TouchableHighlight
        disabled={page === numberOfPages}
        style={page === numberOfPages ? styles.btnDisable : styles.btn}
        testID="NextPage"
        onPress={onNextPage}
      >
        <Text style={styles.btnText}>{'+'}</Text>
      </TouchableHighlight>
      <TouchableHighlight
        disabled={scale === 1}
        style={scale === 1 ? styles.btnDisable : styles.btn}
        onPress={onZoomOut}
      >
        <Text style={styles.btnText}>{'-'}</Text>
      </TouchableHighlight>
      <View style={styles.btnText}>
        <Text style={styles.btnText}>Scale</Text>
      </View>
      <TouchableHighlight
        disabled={scale >= 3}
        style={scale >= 3 ? styles.btnDisable : styles.btn}
        onPress={onZoomIn}
      >
        <Text style={styles.btnText}>{'+'}</Text>
      </TouchableHighlight>
    </View>
    <View style={styles.row}>
      <View style={styles.btnText}>
        <Text style={styles.btnText}>{'Horizontal:'}</Text>
      </View>
      <TouchableHighlight style={styles.btn} onPress={onSwitchHorizontal}>
        {!horizontal ? (
          <Text style={styles.btnText}>{'false'}</Text>
        ) : (
          <Text style={styles.btnText}>{'true'}</Text>
        )}
      </TouchableHighlight>
      <View style={styles.btnText}>
        <Text style={styles.btnText}>{'Scrollbar'}</Text>
      </View>
      <TouchableHighlight style={styles.btn} onPress={onToggleScrollbars}>
        {!showsVerticalScrollIndicator ? (
          <Text style={styles.btnText}>{'hidden'}</Text>
        ) : (
          <Text style={styles.btnText}>{'shown'}</Text>
        )}
      </TouchableHighlight>
    </View>
    <View style={styles.row}>
      <View style={styles.btnText}>
        <Text style={styles.btnText}>{'Directional lock:'}</Text>
      </View>
      <TouchableHighlight
        style={styles.btn}
        testID="DirectionalLock"
        onPress={onToggleDirectionalLock}
      >
        <Text style={styles.btnText}>
          {directionalLockEnabled ? 'true' : 'false'}
        </Text>
      </TouchableHighlight>
    </View>
  </>
);

const PDFExample = () => {
  const pdfRef = useRef<PdfRef | null>(null);
  const objectUrlRef = useRef<string | null>(null);
  const [page, setPage] = useState(1);
  const [scale, setScale] = useState(1);
  const [numberOfPages, setNumberOfPages] = useState(0);
  const [horizontal, setHorizontal] = useState(false);
  const [showsHorizontalScrollIndicator, setShowsHorizontalScrollIndicator] =
    useState(true);
  const [showsVerticalScrollIndicator, setShowsVerticalScrollIndicator] =
    useState(true);
  const [directionalLockEnabled, setDirectionalLockEnabled] = useState(false);

  const [, setObjectUrl] = useState<string>();
  const [, setBlob] = useState<Blob>();
  const { width } = useWindowDimensions();

  useEffect(() => {
    let isMounted = true;

    (async () => {
      const url = 'https://www.africau.edu/images/default/sample.pdf';
      // handling blobs larger than 64 KB on Android requires patching React Native
      const result = await fetch(url);
      const blob = await result.blob();
      const objectURL = URL.createObjectURL(blob);

      if (!isMounted) {
        URL.revokeObjectURL(objectURL);
        return;
      }

      objectUrlRef.current = objectURL;
      setBlob(blob); // keep blob in state so it doesn't get garbage-collected
      setObjectUrl(objectURL);
    })();

    return () => {
      isMounted = false;

      if (objectUrlRef.current) {
        URL.revokeObjectURL(objectUrlRef.current);
      }
    };
  }, []);

  const prePage = (): void => {
    const previousPage = page > 1 ? page - 1 : 1;
    pdfRef.current?.setPage(previousPage);
    console.log(`prePage: ${previousPage}`);
  };

  const nextPage = (): void => {
    const next = page + 1 > numberOfPages ? numberOfPages : page + 1;
    pdfRef.current?.setPage(next);
    console.log(`nextPage: ${next}`);
  };

  const zoomOut = (): void => {
    const nextScale = scale > 1 ? scale / 1.2 : 1;
    setScale(nextScale);
    console.log(`zoomOut scale: ${nextScale}`);
  };

  const zoomIn = (): void => {
    let nextScale = scale * 1.2;
    nextScale = nextScale > 3 ? 3 : nextScale;
    setScale(nextScale);
    console.log(`zoomIn scale: ${nextScale}`);
  };

  const switchHorizontal = (): void => {
    setHorizontal(currentHorizontal => !currentHorizontal);
  };

  const switchShowsHorizontalScrollIndicator = (): void => {
    setShowsHorizontalScrollIndicator(currentValue => !currentValue);
  };

  const switchShowsVerticalScrollIndicator = (): void => {
    setShowsVerticalScrollIndicator(currentValue => !currentValue);
  };

  const source: { uri: string; cache?: boolean } =
    Platform.OS === 'windows'
      ? { uri: 'ms-appx:///test.pdf' }
      : {
          uri: 'https://ontheline.trincoll.edu/images/bookdown/sample-local-pdf.pdf',
          cache: true,
        };
  // const source = { uri: objectUrl! };
  const widthStyles = createWidthStyles(width);

  return (
    <SafeAreaView style={styles.container} edges={{ top: 'maximum' }}>
      <PDFHeader
        page={page}
        scale={scale}
        numberOfPages={numberOfPages}
        horizontal={horizontal}
        showsVerticalScrollIndicator={showsVerticalScrollIndicator}
        directionalLockEnabled={directionalLockEnabled}
        onPrePage={prePage}
        onNextPage={nextPage}
        onZoomOut={zoomOut}
        onZoomIn={zoomIn}
        onSwitchHorizontal={switchHorizontal}
        onToggleScrollbars={() => {
          switchShowsHorizontalScrollIndicator();
          switchShowsVerticalScrollIndicator();
        }}
        onToggleDirectionalLock={() => {
          setDirectionalLockEnabled(currentValue => !currentValue);
        }}
      />
      <View style={widthStyles.pdfContainer}>
        <Pdf
          ref={pdfRef}
          trustAllCerts={false}
          source={source}
          scale={scale}
          horizontal={horizontal}
          directionalLockEnabled={directionalLockEnabled}
          showsVerticalScrollIndicator={showsVerticalScrollIndicator}
          showsHorizontalScrollIndicator={showsHorizontalScrollIndicator}
          onLoadComplete={(
            loadedNumberOfPages: number,
            filePath: string,
            dims: { width: number; height: number },
            tableContents: unknown,
          ) => {
            setNumberOfPages(loadedNumberOfPages);
            console.log(`total page count: ${loadedNumberOfPages}`);
            console.log(tableContents, dims, filePath);
          }}
          onPageChanged={(currentPage: number, loadedNumberOfPages: number) => {
            setPage(currentPage);
            console.log(
              `current page: ${currentPage} / ${loadedNumberOfPages}`,
            );
          }}
          onError={(error: unknown) => {
            console.log(error);
          }}
          style={styles.pdf}
        />
      </View>
    </SafeAreaView>
  );
};

export default PDFExample;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-start',
    // marginTop: 25,
  },
  btn: {
    margin: 2,
    padding: 2,
    backgroundColor: 'aqua',
  },
  btnDisable: {
    margin: 2,
    padding: 2,
    backgroundColor: 'gray',
  },
  btnText: {
    margin: 2,
    padding: 2,
  },
  pdf: {
    flex: 1,
  },
  row: {
    flexDirection: 'row',
  },
});
