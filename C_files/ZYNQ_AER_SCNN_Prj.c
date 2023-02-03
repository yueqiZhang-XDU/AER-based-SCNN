/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */


#include <stdio.h>
#include <string.h>
#include <string.h>
#include <stdlib.h>
#include "math.h"
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xplatform_info.h"          // ZYNQ 的 API
#include "sleep.h"
#include "xtime_l.h"
//custom_ip
#include "SCNN_AXI_Conncetor.h"
//interrupt
#include "xil_exception.h"           // ARM核的异常处理 API
#include "xgpiops.h"
#include "xscugic.h"
//SD card
#include "xsdps.h"		             /* SD device driver */
#include "ff.h"                   //FatFs: Fat file system


// MIO device for interrupt
	#define GPIO_DEVICE_ID  	XPAR_PS7_GPIO_0_DEVICE_ID // MIO device
	#define GPIO_INTERRUPT_ID	XPAR_XGPIOPS_0_INTR       //GPIO interrupt ID
	#define INTC_DEVICE_ID		XPAR_SCUGIC_0_DEVICE_ID	  // General interrupt controller
	#define KEY_INTR_ID 		XPAR_XGPIOPS_0_INTR
	#define PS_KEY_MIO			50					      // KEY MIO port
	#define PS_LED_MIO			0						  // LED MIO port

	#define GPIO_INPUT  		0
	#define GPIO_OUTPUT 		1
	static int Key_flag;  				// if interrupt happens Key_flag=1 , after deal with the interrupt Key_flag set to zero
	//static int Result_out;

// PL interrupt
	#define PL_INTR_ID			XPS_FPGA0_INT_ID


	#define image_X				160
	#define image_Y				250
	#define Pixel_size       	1
	#define bmp_read_stride 	image_Y * Pixel_size
	#define bmp_frame_size 		image_X * image_Y * Pixel_size
	#define filter_size  		7
	#define pad         		3

// SCNN IP AXI device address
#define base_addr 		XPAR_SCNN_AXI_CONNCETOR_0_S00_AXI_BASEADDR
#define bias_addr_reg0	SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG0_OFFSET
#define bias_addr_reg1	SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG1_OFFSET
#define bias_addr_reg2	SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG2_OFFSET
#define bias_addr_reg3	SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG3_OFFSET
#define bias_addr_reg4  SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG4_OFFSET
#define bias_addr_reg5 	SCNN_AXI_CONNCETOR_S00_AXI_SLV_REG5_OFFSET

// write into register : SCNN_TOP_IP_mWriteReg(BaseAddress, RegOffset, Data)
//  read from register : SCNN_TOP_IP_mReadReg(BaseAddress, RegOffset)

//----some about the operation of .bmp files--------
//type define
	// AER buffer struct define 创建用于包含AER信息的结构体
	struct AER
	{
	    u32 	AER_value;
	    int 	AER_X;
	    int 	AER_Y;
	};
	// AER quick sort compare function
	int cmp_AER (const void * AER1, const void * AER2)
	{
	    return ( ((struct AER*)AER1) -> AER_value -  ((struct AER*)AER2) -> AER_value );  //比较的值是两个AER的值相减
	}

	// 文件信息头结构体
	typedef struct tagBITMAPFILEHEADER
	{
	    //unsigned short bfType;        // 19778，必须是BM字符串，对应的十六进制为0x4d42,十进制为19778，否则不是bmp格式文件
	    unsigned int   bfSize;        // 文件大小 以字节为单位(2-5字节)
	    unsigned short bfReserved1;   // 保留，必须设置为0 (6-7字节)
	    unsigned short bfReserved2;   // 保留，必须设置为0 (8-9字节)
	    unsigned int   bfOffBits;     // 从文件头到像素数据的偏移  (10-13字节)
	} BITMAPFILEHEADER;

	//图像信息头结构体
	typedef struct tagBITMAPINFOHEADER
	{
	    unsigned int    biSize;          // 此结构体的大小 (14-17字节)
	    long            biWidth;         // 图像的宽  (18-21字节)
	    long            biHeight;        // 图像的高  (22-25字节)
	    unsigned short  biPlanes;        // 表示bmp图片的平面属，显然显示器只有一个平面，所以恒等于1 (26-27字节)
	    unsigned short  biBitCount;      // 一像素所占的位数，一般为24   (28-29字节)
	    unsigned int    biCompression;   // 说明图象数据压缩的类型，0为不压缩。 (30-33字节)
	    unsigned int    biSizeImage;     // 像素数据所占大小, 这个值应该等于上面文件头结构中bfSize-bfOffBits (34-37字节)
	    long            biXPelsPerMeter; // 说明水平分辨率，用象素/米表示。一般为0 (38-41字节)
	    long            biYPelsPerMeter; // 说明垂直分辨率，用象素/米表示。一般为0 (42-45字节)
	    unsigned int    biClrUsed;       // 说明位图实际使用的彩色表中的颜色索引数（设为0的话，则说明使用所有调色板项）。 (46-49字节)
	    unsigned int    biClrImportant;  // 说明对图象显示有重要影响的颜色索引的数目，如果是0，表示都重要。(50-53字节)
	} BITMAPINFOHEADER;

	//24位图像素信息结构体,即调色板
	typedef struct _PixelInfo {
	    unsigned char rgbBlue;   //该颜色的蓝色分量  (值范围为0-255)
	    unsigned char rgbGreen;  //该颜色的绿色分量  (值范围为0-255)
	    unsigned char rgbRed;    //该颜色的红色分量  (值范围为0-255)
	    unsigned char rgbReserved;// 保留，必须为0
	} PixelInfo;

//DoG filter
double core[49]={0.0639626401768356,-0.0112084893311923,-0.0782246936009478,-0.103130501444779 ,-0.0782246936009478,-0.0112084893311923,0.0639626401768356,
                 -0.0112084893311923,-0.127534999288127, -0.161281283604526,-0.131441192331602,-0.161281283604526,   -0.127534999288127,-0.0112084893311923,
                 -0.0782246936009478,-0.161281283604526, 0.116568735165744,0.433004250795260,   0.116568735165744,   -0.161281283604526,-0.0782246936009478,
                 -0.103130501444779 , -0.131441192331602,0.433004250795260,1                ,  0.433004250795260,   -0.131441192331602, -0.103130501444779,
                 -0.0782246936009478,-0.161281283604526, 0.116568735165744,0.433004250795260,  0.116568735165744,    -0.161281283604526,-0.0782246936009478,
                 -0.0112084893311923,-0.127534999288127,-0.161281283604526,-0.131441192331602,  -0.161281283604526,  -0.127534999288127,-0.0112084893311923,
                 0.0639626401768356,-0.0112084893311923,-0.0782246936009478,-0.103130501444779,-0.0782246936009478, -0.0112084893311923,0.0639626401768356};

//--------------------------------------------------

//GPIO struct
	XGpioPs Gpio_PTR;					/* The driver instance for GPIO Device. */
// GIC struct
	XScuGic IntcInstance;				/* Interrupt Controller Instance */
//SD struct
	XSdPs 	SdInstance;
	FIL 	fil;
	FATFS	fatfs;
	FRESULT	file_result;


//bmp 文件内容
	BITMAPFILEHEADER fileHeader;
	BITMAPINFOHEADER infoHeader;
	PixelInfo        RGBQuad[256];

	unsigned char 	read_line_buff[bmp_read_stride];
	unsigned char 	read_line_buff_pad[2];
	double     		image_data_buff[image_X+2*pad][image_Y+2*pad];
	int 			AER [16384];
	// unsigned 8-bit  it is a specific data type of the ZYNQ
	char 			PL_intr_message[]="This is PL info";
	u32  			SCNN_inference_result;

//fuction declearation
	//GPIO interrupt
	int  Intr_init_Function(XScuGic *InstancePtr, u16 DeviceId, XGpioPs *GpioInstancePtr);
	void GpioHandler(void * CallbackRef);
	int GPIO_initialize(XScuGic *Intc, XGpioPs *Gpio, u16 DeviceId, u16 GpioIntrId);
	// PL interrupt
	int  PL_interrupt_Setup(XScuGic *InstancePtr);
	void PL_IntrHandler(void *CallBackRef);
	//SD card read and operate
	int  SD_initialize(void);
	void bmp_read(char * bmp, u32 stride, u8 *pimage);
	void showBmpHead(BITMAPFILEHEADER pBmpHead);
	void showBmpInfoHead(BITMAPINFOHEADER pBmpinfoHead);
	void bmp_read_329(char *bmp_file_name, double image_data_buff[][image_Y+2*pad]);
	void DoG_image_filter_with_pad (double in[image_X+2*pad][image_Y+2*pad]);
	void sort(double *a, int *b, int *c, int l);
	void AER_Coding_trans(int *a,int *b, int l);
	void AER_struct_Coding_trans(struct AER* a, int m);


int main()
{
    init_platform();
    int i=0;
    int Status;
    char TMP_name[9];


    xil_printf("System startup \n\r");
    // GPIO initial
    Status = GPIO_initialize(&IntcInstance, &Gpio_PTR, GPIO_DEVICE_ID, GPIO_INTERRUPT_ID);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	else {
		xil_printf("GPIO initialize successful\n\r");
	}
	// PL interrupt initial
	Status = PL_interrupt_Setup(&IntcInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	else {
		xil_printf("PL interrupt initialize successful\n\r");
	}

	// SD card initial
	Status = SD_initialize();
	if (Status != XST_SUCCESS) {
			return XST_FAILURE;
	}
	else {
		xil_printf("SD card initialize successful\n\r");
	}

	xil_printf("press the button to read the first image file\n\r");
	while (1){
		if(Key_flag)
		{
			sprintf(TMP_name, "%04d.bmp", i+1);//sprintf函数打印到字符串中

			xil_printf("The current TMP_name  = %s \n\r",TMP_name);
			// get the image file name by char pointer
			/*	for(int x=0; x<7; x++){
				 *(TMP_name+x) = *(PhotoName+x);
			}
			*/
			xil_printf("The current file_name = %s \n\r",TMP_name);
			//read .bmp image file
			bmp_read_329( TMP_name, image_data_buff);// by checking, we read the right data from the bmp file
			//DoG image flit and AER coding

			DoG_image_filter_with_pad (image_data_buff);


			xil_printf("The current image operation has done\n\r");

		/* check the result output flag of the SCNN IP
		 * when detect the IP output flag, generate an interrupt from PL
		 * in the IntrHandler function, read the classification result and print the result
		 */

			/*
			while(Result_out)
				{

				}
			*/
			Key_flag = 0;
			i=i+1;

		}

	}

    cleanup_platform();
    return 0;
}



int GPIO_initialize(XScuGic *Intc, XGpioPs *Gpio, u16 DeviceId, u16 GpioIntrId)      	//GPIO device initial fuction
{
	int Status;

	XGpioPs_Config *ConfigPtr;  // GPIO device configuration vector
	ConfigPtr = XGpioPs_LookupConfig(DeviceId);// find GPIO device
	// initialize GPIO
	Status = XGpioPs_CfgInitialize(Gpio, ConfigPtr,ConfigPtr->BaseAddr); //initialize GPIO; Status shows weather the output is correct
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	//set GPIO port direction
		XGpioPs_SetDirectionPin(Gpio, PS_LED_MIO, 1);		//output
		XGpioPs_SetOutputEnablePin(Gpio, PS_LED_MIO, 1);	//output enable
		XGpioPs_SetDirectionPin(Gpio, PS_KEY_MIO, 0);		//input

	//set GPIO pin interrupt
		//set interrupt type
		XGpioPs_SetIntrTypePin(Gpio, PS_KEY_MIO, XGPIOPS_IRQ_TYPE_EDGE_RISING);// set  the interrupt type and the interrupt pin
		// Enable pin interrupt
		XGpioPs_IntrEnablePin(Gpio, PS_KEY_MIO);

	// GIC(global interrupt controller) initialize
		//Function GIC initial
		Status = Intr_init_Function(Intc, DeviceId, Gpio);
		if (Status != XST_SUCCESS){
			return XST_FAILURE ;
		}
	return XST_SUCCESS ;
}

int Intr_init_Function(XScuGic *InstancePtr, u16 DeviceId, XGpioPs *GpioInstancePtr)        // config the relationship between GIC and GPIO
{
	int Status ;
	XScuGic_Config *IntcConfig;  //GIC device configuration vectro
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);  //find GIC device

	Status = XScuGic_CfgInitialize(InstancePtr, IntcConfig, IntcConfig->CpuBaseAddress) ;// Initialize GIC
	if (Status != XST_SUCCESS){
		return XST_FAILURE ;
	}

	//---------creat MIO KEY interrupt--------------//
	XScuGic_SetPriorityTriggerType(InstancePtr, KEY_INTR_ID, 0xA0, 0x3);//set priority and trigger type

	//register the interrupt handler
	Status = XScuGic_Connect(InstancePtr, KEY_INTR_ID,
			(Xil_ExceptionHandler)GpioHandler,            //put the interrupt function of the GPIO interrupt into the GIC to call when the interrupt happened
			(void *)GpioInstancePtr) ;
	if (Status != XST_SUCCESS){
		return XST_FAILURE ;
	}

	// Enable the interrupt
	XScuGic_Enable(InstancePtr, KEY_INTR_ID) ;

	Xil_ExceptionInit();

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, InstancePtr); // Xil_ExceptionHandler is a pointer to the GPIO_handler

	Xil_ExceptionEnable();

	return XST_SUCCESS ;
}

void GpioHandler(void *callbackRef)
{
	XGpioPs *GpioInstancePtr = (XGpioPs *)callbackRef ;
	int Int_val ;
	Int_val = XGpioPs_IntrGetStatusPin(GpioInstancePtr, PS_KEY_MIO) ;
	//中断服务程序内容
	xil_printf("key interrupt is successful\n\r");

	XGpioPs_IntrClearPin(GpioInstancePtr, PS_KEY_MIO) ;
	if (Int_val)
		Key_flag = 1 ;

}

int SD_initialize(){
	TCHAR *Path = "0:/";  					//file math

	//mount
	file_result = f_mount(&fatfs, Path, 1);  //mount SD card is the first step
	if (file_result != FR_OK) {
		 xil_printf("Volume is not FAT formated; formating FAT\r\n");
		 return XST_FAILURE;
	}
	else {

		return XST_SUCCESS;
	}
}

void showBmpHead(BITMAPFILEHEADER pBmpHead)
{  //定义显示信息的函数，传入文件头结构体
    xil_printf("file size of the BMP : %dkb\n\r", fileHeader.bfSize/1024);
    xil_printf("Reserved word1 must be 0：%d\n\r",  fileHeader.bfReserved1);
    xil_printf("Reserved word2 must be 0：%d\n\r",  fileHeader.bfReserved2);
    xil_printf("the practical offset bits : %d\n\r",  fileHeader.bfOffBits);
}

void showBmpInfoHead(BITMAPINFOHEADER pBmpinfoHead)
{//定义显示信息的函数，传入的是信息头结构体
    xil_printf("位图信息头:\n\r" );
    xil_printf("信息头的大小:%d\n\r" ,infoHeader.biSize);
    xil_printf("位图宽度bit width:%d\n\r" ,infoHeader.biWidth);
    xil_printf("位图高度bit height:%d\n\r" ,infoHeader.biHeight);
    xil_printf("the number of rgb plans :%d\n\r" ,infoHeader.biPlanes);
    xil_printf("每个像素的位数 the bit number of each pixel :%d\n\r" ,infoHeader.biBitCount);
    xil_printf("压缩方式:%d\n\r" ,infoHeader.biCompression);
    xil_printf("图像的大小:%d\n\r" ,infoHeader.biSizeImage);
    xil_printf("水平方向分辨率:%d\n\r" ,infoHeader.biXPelsPerMeter);
    xil_printf("垂直方向分辨率:%d\n\r" ,infoHeader.biYPelsPerMeter);
    xil_printf("使用的颜色数:%d\n\r" ,infoHeader.biClrUsed);
    xil_printf("重要颜色数:%d\n\r" ,infoHeader.biClrImportant);
}

void bmp_read_329(char *bmp_file_name, double image_data_buff[][image_Y+2*pad] )
{
	FRESULT res;
	unsigned int br;         // File R/W count
	unsigned short  fileType;


	xil_printf("***************Open BMP file name : %s****************\n\r", bmp_file_name);
	res = f_open(&fil, bmp_file_name, FA_OPEN_EXISTING | FA_READ );
	if(res != FR_OK)
	{
		xil_printf("*****************error open BMP file***************\n\r");
	}

	res = f_read(&fil, &fileType, sizeof(unsigned short),&br );// First read the file flag
	if( (fileType = 0x4d42 ) ) 	 //judge the file type
	{
        xil_printf("The file type identification is correct!\n\r" );

		res = f_read(&fil, &fileHeader, sizeof(BITMAPFILEHEADER), &br); 	//read file header
		//showBmpHead(fileHeader);
		res = f_read(&fil, &infoHeader, sizeof(BITMAPINFOHEADER), &br);		//read info header
		//showBmpInfoHead(infoHeader);
		res = f_read(&fil, RGBQuad, 	256*sizeof(PixelInfo)	, &br);	//read color Quad

		//read the bmp image data
        for (int i=0; i<image_X; i++){
        	res = f_read(&fil, &read_line_buff, 250*sizeof(unsigned char), &br);
            for (int j=0; j<image_Y; j++){
                image_data_buff[image_X-1-i][j]=(double)read_line_buff[j];
            }
            res = f_read(&fil, &read_line_buff_pad, 2*sizeof(unsigned char), &br);
        }

        xil_printf("bmp file %s read finished\n\r",bmp_file_name);
        f_close(&fil);
	}
}


void DoG_image_filter_with_pad (double in[image_X+2*pad][image_Y+2*pad])
{
    // core 是double类型的，已经
    //double Image_tmp[Image_X][Image_Y];
    double TMP_data;
/*
    double tmp_data_buff[16384];
    int    AER_M[16384];// 存储AER的行地址
    int    AER_N[16384];// 存储AER的列地址
*/
    int    cnt=0;

    struct AER AER_list[16384];



    XTime  tEnd_DoG,tCur_DoG;  // calculate the run time of the DoG operation
    u32    ttUsed_DoG;
    XTime  tEnd_Sort,tCur_Sort;
    u32    ttUsed_Sort;

    XTime  tEnd_QSort,tCur_QSort;
    u32    ttUsed_QSort;

	XTime_GetTime(&tCur_DoG);
    //DoG 滤波，设置board，设置阈值
    for (int i=0; i<image_X; i++ ){
        if(i>=filter_size && i < image_X-filter_size)  // 0- [7-242]-249
        {   //i=7 ---- i=(160-7)-1
            for (int j=0; j<image_Y; j++){
             if(j>=filter_size && j < image_Y-filter_size)
             {// j=7 ---- j=(250-7)-1
                 TMP_data        = core[0 ]*in[  i][  j]+core[1 ]*in[  i][j+1]+core[2 ]*in[  i][j+2]+core[3 ]*in[  i][j+3]+core[4 ]*in[  i][j+4]+core[5 ]*in[  i][j+5]+core[6 ]*in[  i][j+6]
                                  +core[7 ]*in[i+1][  j]+core[8 ]*in[i+1][j+1]+core[9 ]*in[i+1][j+2]+core[10]*in[i+1][j+3]+core[11]*in[i+1][j+4]+core[12]*in[i+1][j+5]+core[13]*in[i+1][j+6]
                                  +core[14]*in[i+2][  j]+core[15]*in[i+2][j+1]+core[16]*in[i+2][j+2]+core[17]*in[i+2][j+3]+core[18]*in[i+2][j+4]+core[19]*in[i+2][j+5]+core[20]*in[i+2][j+6]
                                  +core[21]*in[i+3][  j]+core[22]*in[i+3][j+1]+core[23]*in[i+3][j+2]+core[24]*in[i+3][j+3]+core[25]*in[i+3][j+4]+core[26]*in[i+3][j+5]+core[27]*in[i+3][j+6]
                                  +core[28]*in[i+4][  j]+core[29]*in[i+4][j+1]+core[30]*in[i+4][j+2]+core[31]*in[i+4][j+3]+core[32]*in[i+4][j+4]+core[33]*in[i+4][j+5]+core[34]*in[i+4][j+6]
                                  +core[35]*in[i+5][  j]+core[36]*in[i+5][j+1]+core[37]*in[i+5][j+2]+core[38]*in[i+5][j+3]+core[39]*in[i+5][j+4]+core[40]*in[i+5][j+5]+core[41]*in[i+5][j+6]
                                  +core[42]*in[i+6][  j]+core[43]*in[i+6][j+1]+core[44]*in[i+6][j+2]+core[45]*in[i+6][j+3]+core[46]*in[i+6][j+4]+core[47]*in[i+6][j+5]+core[48]*in[i+6][j+6];
               //  Image_tmp[i][j]=TMP_data;
                 if(TMP_data>16)
                 {
/*
                     tmp_data_buff[cnt]=1.0/TMP_data;
                     AER_M[cnt]=i+1;
                     AER_N[cnt]=j+1;
*/

                     AER_list[cnt].AER_value = (u32)(1.0/TMP_data *100000000);
                     AER_list[cnt].AER_X     = i+1;
                     AER_list[cnt].AER_Y     = j+1;

                     cnt++;
                 }
             }
            }
        }
    }
    XTime_GetTime(&tEnd_DoG);
	ttUsed_DoG  = ((tEnd_DoG - tCur_DoG)*1000000)   / (COUNTS_PER_SECOND);  // DoG operation time
	xil_printf("The operating time of the DoG is %d us \n\r", ttUsed_DoG);
    //sort
/*
	XTime_GetTime(&tCur_Sort);
	sort(tmp_data_buff, AER_M, AER_N, cnt);
	XTime_GetTime(&tEnd_Sort);
	ttUsed_Sort = ((tEnd_Sort - tCur_Sort)*1000000) / (COUNTS_PER_SECOND);  // sort operation time
	xil_printf("The operation time of the Sort operation is %d us \n\r", ttUsed_Sort);
*/


	// quickly sort

	XTime_GetTime(&tCur_QSort);
	qsort(AER_list, cnt, sizeof(AER_list[0]), cmp_AER);// quick sort operation
	XTime_GetTime(&tEnd_QSort);
	ttUsed_QSort = ((tEnd_QSort - tCur_QSort)*1000000) / (COUNTS_PER_SECOND);//quick sort operation time
	xil_printf("The operation time of the Quick Sort operation is %d us \n\r", ttUsed_QSort);

//  In order to Send AER Spikes  对于产生的AER脉冲进行传播

//  AER_Coding_trans(AER_M,AER_N,cnt); // in this function the AER is transmitted to the SCNN IP
	AER_struct_Coding_trans( AER_list, cnt );

}



void sort(double *a, int *b, int *c, int l)
{
    // a 是数据值，b和c为数据结果

    int i, j;
    double v;
    int M;
    int N;

    //排序主体
    for (i = 0; i < l - 1; i++){
        for (j = i + 1; j < l; j++) {
            if (a[i] > a[j])//如前面的比后面的大，则交换。
            {
                v = a[i];
                a[i] = a[j];
                a[j] = v;
                M=b[i];
                N=c[i];
                b[i] = b[j];
                b[j] = M;
                c[i] = c[j];
                c[j] = N;
            }
        }
    }

}

// here we need to change the sort function to speed up the processing



void AER_Coding_trans(int *a,int *b, int l)   // l is the number of AER spike
{
	u32 AER_buffer[16384];  // creat an AER message buffer
	int X_10;// hang
	int Y_10;// lie

	for (int K=0; K<l; K++){
		// get the spike position
		X_10 = a[K];
		Y_10 = b[K];
		// trans the position message dec to bin
		AER_buffer[K]=(u32) X_10*256+Y_10;
	}

	// write the data into the AXI register in order to send message

	xil_printf("transmit AER to the SCNN IP \n\r");
	SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg0, 0x00000001);
	for (int Z=0; Z<l; Z++){
		//xil_printf("the %dth AER data is %d=(%d,%d) \n\r", Z,AER_buffer[Z],a[Z],b[Z]);
		SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg1, AER_buffer[Z]);
	}
	SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg0, 0x00000000);

}

//void AER_Coding_trans()
void AER_struct_Coding_trans(struct AER* a, int m)
{
    u32 AER_buffer[16384];  // creat an AER message buffer
    int X_10;// hang
    int Y_10;// lie

    for (int K=0; K<m; K++)
    {
            // get the spike position
            X_10 = a[K].AER_X;
            Y_10 = a[K].AER_Y;
            // trans the position message dec to bin
            AER_buffer[K]=(u32) X_10*256+Y_10;
     }
	// write the data into the AXI register in order to send message
	xil_printf("transmit AER to the SCNN IP \n\r");
	SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg0, 0x00000001);
	for (int Z=0; Z<m; Z++){
		//xil_printf("the %dth AER data is %d=(%d,%d) \n\r", Z,AER_buffer[Z],a[Z],b[Z]);
		SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg1, AER_buffer[Z]);
	}
	SCNN_AXI_CONNCETOR_mWriteReg(base_addr, bias_addr_reg0, 0x00000000);

}

// set the PL interrupt


int PL_interrupt_Setup(XScuGic *InstancePtr)// the input parameter is   	(XScuGic IntcInstance;	)             int Intr_init_Function(XScuGic *InstancePtr, u16 DeviceId, XGpioPs *GpioInstancePtr)
{
	int Status;
	//PL intr set priority and trigger type
	XScuGic_SetPriorityTriggerType(InstancePtr, PL_INTR_ID, 0xB0, 0x3);//set priority and trigger type   上升沿触发set

	// regist the interrupt in the GIC
	Status = XScuGic_Connect(InstancePtr, PL_INTR_ID,
			(Xil_ExceptionHandler)PL_IntrHandler,            //put the interrupt function of the GPIO interrupt into the GIC to call when the interrupt happened
			(void *)PL_intr_message) ;
	if (Status != XST_SUCCESS){
		return XST_FAILURE ;
	}
	XScuGic_Enable(InstancePtr, PL_INTR_ID);
	xil_printf("PL interrupt setup successful\n\r");
	return XST_SUCCESS ;
}



void PL_IntrHandler(void *CallBackRef)    //  The PL interrupt handler
{
	// read the register value from the reg3
	SCNN_inference_result = SCNN_AXI_CONNCETOR_mReadReg(base_addr, bias_addr_reg2);
	if(SCNN_inference_result == 0x00000002){
		xil_printf("The Enter Image Type is Face\n\r");  // result = 32'b02  SVM 结果为负数  face
	}
	else if(SCNN_inference_result == 0x00000001){
		xil_printf("The Enter Image Type is Moto\n\r");  // result = 32'b01  SVM 结果为正数   moto
	}
	else if(SCNN_inference_result == 0x00000000){
		xil_printf("The Enter Image Type is 0\n\r");
		xil_printf("*****press the button to read the next image file*****\n\r");
	}



}



