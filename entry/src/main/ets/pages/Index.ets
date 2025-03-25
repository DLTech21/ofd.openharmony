import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { readOFD, verifyOFD, drawPage, countPages } from 'ofdlibrary'
import { hilog } from '@kit.PerformanceAnalysisKit';
import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @State message: string = '选择OFD';
  @State myMap: Map<string, string> = new Map([
    ["宋体", this.context.filesDir + '/simsun.ttf'],
    ["simsun", this.context.filesDir + '/simsun.ttf'],
    ["楷体", this.context.filesDir + '/simkai.ttf'],
    ["simsun", this.context.filesDir + '/simkai.ttf'],
    ["kaiti", this.context.filesDir + '/simkai.ttf'],
    ["kaiti_gb2312", this.context.filesDir + '/simkai.ttf'],
    ["楷体_gb2312", this.context.filesDir + '/simkai.ttf'],
    ["courier new", this.context.filesDir + '/cour.ttf'],
    ["仿宋", this.context.filesDir + '/SIMFANG.ttf'],
    ["仿宋_gb2312", this.context.filesDir + '/SIMFANG.ttf'],
    ["小标宋体", this.context.filesDir + '/fzxbst.ttf'],
    ["方正小标宋简体", this.context.filesDir + '/fzxbst.ttf'],
    ["latha", this.context.filesDir + '/Latha.ttf'],
    ["tahoma", this.context.filesDir + '/Tahoma.ttf'],
    ["times new roman", this.context.filesDir + '/times.ttf'],
    ["timesnewromanpsmt", this.context.filesDir + '/times.ttf'],
    ["arial", this.context.filesDir + '/arial.ttf'],
    ["calibri", this.context.filesDir + '/calibri.ttf'],
    ["symbol", this.context.filesDir + '/symbol.ttf'],
    ["stcaiyun", this.context.filesDir + '/STCAIYUN.ttf'],
    ["mongolian baiti", this.context.filesDir + '/monbaiti.ttf'],
    ["wingdings", this.context.filesDir + '/wingding.ttf'],
  ]);
  @State imagePath: string = "";
  @State currentIndex: number = 0;
  @State totalPages: number = 0;

  aboutToAppear() {
    this.copy()
  }

  previousImage() {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      let ret = drawPage(this.currentIndex, this.context.filesDir, this.myMap)
      if (ret == 1) {
        this.imagePath = "file://" + this.context.filesDir + "/page" + this.currentIndex + ".png"
      }
    }
  }

  nextImage() {
    if (this.currentIndex < this.totalPages - 1) {
      this.currentIndex++;
      let ret = drawPage(this.currentIndex, this.context.filesDir, this.myMap)
      if (ret == 1) {
        this.imagePath = "file://" + this.context.filesDir + "/page" + this.currentIndex + ".png"
      }
    }
  }

  build() {
    Column({}) {
      Column() {
        Text(this.message)
          .id('HelloWorld')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(() => {
            let documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.selectMode = picker.DocumentSelectMode.FILE
            documentSelectOptions.fileSuffixFilters = ['ofd']
            let documentPicker = new picker.DocumentViewPicker(this.context);
            documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
              let ret = readOFD(documentSelectResult[0])
              if (ret == 0) {
                this.totalPages = countPages()
                ret = drawPage(this.currentIndex, this.context.filesDir, this.myMap)
                if (ret == 1) {
                  this.imagePath = "file://" + this.context.filesDir + "/page" + this.currentIndex + ".png"
                }
              }
            }).catch((err: BusinessError) => {
              console.error('DocumentViewPicker.select failed with err: ' + JSON.stringify(err));
            });
          })
      }.width('100%').height(60)

      Column() {
        // 图片展示
        Image(this.imagePath)
          .width('100%')
          .height('auto')
          .objectFit(ImageFit.Contain);

        if (this.totalPages > 0) {
          Row() {
            Button('上一页')
              .enabled(this.currentIndex != 0)
              .onClick(() => this.previousImage());

            Button('下一页')
              .enabled(this.currentIndex != this.totalPages - 1)
              .onClick(() => this.nextImage());
          }
        }
      }

    }

  }

  copy() {
    this.context.resourceManager.getRawFd("font.zip", (err, data) => {
      let sandboxPath = this.context.filesDir
      console.log("沙箱路径：" + sandboxPath)
      fs.mkdtempSync(sandboxPath + "/XXXXXX")
      let filePath = this.context.tempDir + "/font.zip"
      console.log("压缩文件路径：" + filePath)
      let dest = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
      let bufsize = 4096
      let buf = new ArrayBuffer(bufsize)
      let off = 0, len = 0, readedLen = 0
      /**
       * 通过buffer将rawfile文件内容copy到沙箱路径
       */
      while (len = fs.readSync(data.fd, buf, { offset: data.offset + off, length: bufsize })) {
        readedLen += len
        fs.writeSync(dest.fd, buf, { offset: off, length: len })
        off = off + len
        if ((data.length - readedLen) < bufsize) {
          bufsize = data.length - readedLen
        }
      }
      fs.close(dest.fd)
      // 对沙箱路径下的压缩文件进行解压
      zlib.decompressFile(filePath, sandboxPath)
      this.context.resourceManager.closeRawFd("font.zip")
    })
  }
}