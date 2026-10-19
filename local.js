import PropTypes from 'prop-types';
import {Platform} from 'react-native';
import PdfRenderer from './PdfRenderer';

// A local source belongs to the caller. This entry point never copies or deletes it.
export default class LocalPdf extends PdfRenderer {
    static propTypes = {
        ...PdfRenderer.propTypes,
        source: PropTypes.shape({uri: PropTypes.string.isRequired}).isRequired,
    };

    componentDidMount() {
        this._loadLocalSource();
    }

    componentDidUpdate(prevProps) {
        if (prevProps.source?.uri !== this.props.source?.uri) {
            this._loadLocalSource();
        }
    }

    _loadLocalSource() {
        try {
            const uri = this.props.source?.uri;
            if (typeof uri !== 'string' || !uri || uri.includes('\0')) {
                throw new Error('LocalPdf requires a local file URI or an absolute file path.');
            }

            let path;
            if (/^file:\/\/\//i.test(uri)) {
                path = decodeURIComponent(uri.slice('file://'.length));
                if (Platform.OS === 'windows' && /^\/[a-z]:\//i.test(path)) {
                    path = path.slice(1);
                }
            } else if (uri.startsWith('/') ||
                (Platform.OS === 'windows' && (/^[a-z]:[\\/]/i.test(uri) || uri.startsWith('\\\\')))) {
                // Raw paths may contain literal percent signs. Only decode file URIs.
                path = uri;
            } else {
                throw new Error('LocalPdf requires a local file URI or an absolute file path. Download or copy other sources before displaying them.');
            }
            if (path.includes('\0')) {
                throw new Error('LocalPdf received an invalid file path.');
            }

            this.setState({path, isDownloaded: true, progress: 1});
        } catch (error) {
            this.setState({path: '', isDownloaded: false, progress: 0});
            this._onError(error);
        }
    }
}
