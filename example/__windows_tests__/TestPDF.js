import { driver, By2 } from 'selenium-appium'
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';


const setup = require('../jest-windows/driver.setup');
jest.setTimeout(50000);

beforeAll(() => {
  return driver.startWithCapabilities(setup.capabilites);
});

afterAll(() => {
  return driver.quit();
});

function pngFromBase64(base64) {
  const pngBuffer = Buffer.from(base64, 'base64');
  return PNG.sync.read(pngBuffer);
};

const pixelThreshold = 10; // Allow 10 pixel difference, to account for anti-aliasing differences.

function pixelDiffPNGs(img1, img2) {
  return pixelmatch(img1.data, img2.data, null, img1.width, img1.height);
}

describe('Test App', () => {

  test('App loads PDF', async () => {
    await By2.nativeName("PDF Page 21");
  });

  test('Switch to next page', async () => {
    // wait for PDF load
    await By2.nativeName('PDF Page 21');
    let beforeNextPage = pngFromBase64(await driver.takeScreenshot());
    await By2.nativeAccessibilityId('NextPage').click();
    let aferNextPage = pngFromBase64(await driver.takeScreenshot());
    expect(pixelDiffPNGs(beforeNextPage, aferNextPage)).toBeGreaterThanOrEqual(pixelThreshold);
  })

})
