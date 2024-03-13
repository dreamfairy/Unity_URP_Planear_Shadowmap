# Unity_URP_Planear_ShadowMap

Unity Editor : 2021.3.19
基于Unity URP Forward 主相机视角平面阴影

Preview
![Image text](https://github.com/dreamfairy/Unity_URP_Planear_Shadowmap/blob/main/preview/1.gif)

当光源和阴影接收者平面接近平行时有瑕疵
![Image text](https://github.com/dreamfairy/Unity_URP_Planear_Shadowmap/blob/main/preview/2.png)

几乎100%ShadowMap面积利用率的阴影，可以在较小的分辨率下获得更高的清晰度
![Image text](https://github.com/dreamfairy/Unity_URP_Planear_Shadowmap/blob/main/preview/3.png)



优点

1.更节省的性能，阴影投射和阴影接受 不需要做 world space -> lightCamera space变换. 仅需要一个三角形算法求地面投影直角边计算。 可以用近似三角形或者 ∠tan 算法

2.更高的阴影清晰度 几乎100%ShadowMap面积利用率的阴影，可以在较小的分辨率下获得更高的清晰度, 因此可以降低实际ShadowMap尺寸，用以减少带宽

3.可复用URP MainCamera CullResult 直接绘制

缺点

1.只能适配当光线从高处往低处投射，当光线从低处往高处投射时需要修改算法，不能同时兼容高低光线照射角度，当光线平行地平线投射时前后物件无法正确获得阴影

2.复杂且互相叠加的阴影可能会出现渲染错误

3.低分辨率下阴影边缘锯齿抖动需要主相机同时步进适配，但是可能造成主相机观感下降，不如独立阴影相机步进