/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from 'react';
import {
  StyleSheet,
  TouchableHighlight,
  Dimensions,
  View,
  Text,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import Pdf from 'react-native-pdf';
import Orientation from 'react-native-orientation-locker';

const WIN_WIDTH = Dimensions.get('window').width;
const WIN_HEIGHT = Dimensions.get('window').height;

type OrientationType =
  | 'LANDSCAPE-LEFT'
  | 'LANDSCAPE-RIGHT'
  | 'PORTRAIT'
  | string;

interface PDFExampleState {
  page: number;
  scale: number;
  numberOfPages: number;
  horizontal: boolean;
  showsHorizontalScrollIndicator: boolean;
  showsVerticalScrollIndicator: boolean;
  width: number;
  objectURL?: string;
  blob?: Blob;
}

export default class PDFExample extends React.Component<
  Record<string, never>,
  PDFExampleState
> {
  private pdf: any; // usare `Pdf | null` se le typings del pacchetto esportano il tipo

  constructor(props: Record<string, never>) {
    super(props);
    this.state = {
      page: 1,
      scale: 1,
      numberOfPages: 0,
      horizontal: false,
      showsHorizontalScrollIndicator: true,
      showsVerticalScrollIndicator: true,
      width: WIN_WIDTH,
    };
    this.pdf = null;
  }

  _onOrientationDidChange = (orientation: OrientationType): void => {
    if (orientation === 'LANDSCAPE-LEFT' || orientation === 'LANDSCAPE-RIGHT') {
      this.setState({
        width: WIN_HEIGHT > WIN_WIDTH ? WIN_HEIGHT : WIN_WIDTH,
        horizontal: true,
      });
    } else {
      this.setState({
        width: WIN_HEIGHT > WIN_WIDTH ? WIN_HEIGHT : WIN_WIDTH,
        horizontal: false,
      });
    }
  };

  componentDidMount(): void {
    Orientation.addOrientationListener(this._onOrientationDidChange);

    (async () => {
      const url = 'https://www.africau.edu/images/default/sample.pdf';
      // handling blobs larger than 64 KB on Android requires patching React Native (https://github.com/facebook/react-native/pull/31789)
      const result = await fetch(url);
      const blob = await result.blob();
      const objectURL = URL.createObjectURL(blob);
      this.setState({ ...this.state, objectURL, blob }); // keep blob in state so it doesn't get garbage-collected
    })();
  }

  componentWillUnmount(): void {
    Orientation.removeOrientationListener(this._onOrientationDidChange);
  }

  prePage = (): void => {
    const prePage = this.state.page > 1 ? this.state.page - 1 : 1;
    this.pdf?.setPage(prePage);
    console.log(`prePage: ${prePage}`);
  };

  nextPage = (): void => {
    const nextPage =
      this.state.page + 1 > this.state.numberOfPages
        ? this.state.numberOfPages
        : this.state.page + 1;
    this.pdf?.setPage(nextPage);
    console.log(`nextPage: ${nextPage}`);
  };

  zoomOut = (): void => {
    const scale = this.state.scale > 1 ? this.state.scale / 1.2 : 1;
    this.setState({ scale });
    console.log(`zoomOut scale: ${scale}`);
  };

  zoomIn = (): void => {
    let scale = this.state.scale * 1.2;
    scale = scale > 3 ? 3 : scale;
    this.setState({ scale });
    console.log(`zoomIn scale: ${scale}`);
  };

  switchHorizontal = (): void => {
    this.setState({ horizontal: !this.state.horizontal, page: this.state.page });
  };

  switchShowsHorizontalScrollIndicator = (): void => {
    this.setState({
      showsHorizontalScrollIndicator: !this.state.showsHorizontalScrollIndicator,
    });
  };

  switchShowsVerticalScrollIndicator = (): void => {
    this.setState({
      showsVerticalScrollIndicator: !this.state.showsVerticalScrollIndicator,
    });
  };

  render(): React.ReactNode {
    let source: { uri: string; cache?: boolean } =
      Platform.OS === 'windows'
        ? { uri: 'ms-appx:///test.pdf' }
        : { uri: 'https://ontheline.trincoll.edu/images/bookdown/sample-local-pdf.pdf', cache: true };
    // let source = {uri: this.state.objectURL!};

    const Header = () => (
        <>
        <View style={{ flexDirection: 'row' }}>
            <TouchableHighlight
                disabled={this.state.page === 1}
                style={this.state.page === 1 ? styles.btnDisable : styles.btn}
                onPress={() => this.prePage()}
            >
                <Text style={styles.btnText}>{'-'}</Text>
            </TouchableHighlight>
            <View style={styles.btnText}>
                <Text style={styles.btnText}>Page</Text>
            </View>
            <TouchableHighlight
                disabled={this.state.page === this.state.numberOfPages}
                style={
                this.state.page === this.state.numberOfPages
                    ? styles.btnDisable
                    : styles.btn
                }
                testID="NextPage"
                onPress={() => this.nextPage()}
            >
                <Text style={styles.btnText}>{'+'}</Text>
            </TouchableHighlight>
            <TouchableHighlight
                disabled={this.state.scale === 1}
                style={this.state.scale === 1 ? styles.btnDisable : styles.btn}
                onPress={() => this.zoomOut()}
            >
                <Text style={styles.btnText}>{'-'}</Text>
            </TouchableHighlight>
            <View style={styles.btnText}>
                <Text style={styles.btnText}>Scale</Text>
            </View>
            <TouchableHighlight
                disabled={this.state.scale >= 3}
                style={this.state.scale >= 3 ? styles.btnDisable : styles.btn}
                onPress={() => this.zoomIn()}
            >
                <Text style={styles.btnText}>{'+'}</Text>
            </TouchableHighlight>
        </View>
        <View style={{ flexDirection: 'row' }}>
            <View style={styles.btnText}>
                <Text style={styles.btnText}>{'Horizontal:'}</Text>
            </View>
            <TouchableHighlight style={styles.btn} onPress={() => this.switchHorizontal()}>
                {!this.state.horizontal ? (
                <Text style={styles.btnText}>{'false'}</Text>
                ) : (
                <Text style={styles.btnText}>{'true'}</Text>
                )}
            </TouchableHighlight>
            <View style={styles.btnText}>
                <Text style={styles.btnText}>{'Scrollbar'}</Text>
            </View>
            <TouchableHighlight
                style={styles.btn}
                onPress={() => {
                this.switchShowsHorizontalScrollIndicator();
                this.switchShowsVerticalScrollIndicator();
                }}
            >
                {!this.state.showsVerticalScrollIndicator ? (
                <Text style={styles.btnText}>{'hidden'}</Text>
                ) : (
                <Text style={styles.btnText}>{'shown'}</Text>
                )}
            </TouchableHighlight>
        </View>
        </>
    );

    return (
      <SafeAreaView style={styles.container} edges={{top: 'maximum'}}>
        <Header />
        <View style={{ flex: 1, width: this.state.width }}>
            <Pdf
                ref={(pdf: any) => {
                this.pdf = pdf;
                }}
                trustAllCerts={false}
                source={source}
                scale={this.state.scale}
                horizontal={this.state.horizontal}
                showsVerticalScrollIndicator={this.state.showsVerticalScrollIndicator}
                showsHorizontalScrollIndicator={this.state.showsHorizontalScrollIndicator}
                onLoadComplete={(
                numberOfPages: number,
                filePath: string,
                dims: { width: number; height: number },
                tableContents: unknown
                ) => {
                this.setState({
                    numberOfPages: numberOfPages,
                });
                console.log(`total page count: ${numberOfPages}`);
                console.log(tableContents, dims, filePath);
                }}
                onPageChanged={(page: number, numberOfPages: number) => {
                this.setState({
                    page: page,
                });
                console.log(`current page: ${page} / ${numberOfPages}`);
                }}
                onError={(error: unknown) => {
                console.log(error);
                }}
                style={{ flex: 1 }}
            />
        </View>
      </SafeAreaView>
    );
  }
}

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
});