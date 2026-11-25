import 'package:flutter/material.dart';
import '../models/relay_config.dart';
import '../theme/app_themes.dart';

class RelaySwitchTile extends StatelessWidget {
  final RelayConfig relay;
  final AppThemeData theme;
  final Color buttonColor;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const RelaySwitchTile({super.key, required this.relay, required this.theme, required this.buttonColor, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = relay.isOn;
    final glow = active ? buttonColor : theme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds:220),
      margin: const EdgeInsets.only(bottom:13),
      padding: const EdgeInsets.symmetric(horizontal:15, vertical:15),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:active ? [theme.card,buttonColor.withOpacity(.22),theme.card] : [theme.card,theme.card]),
        borderRadius:BorderRadius.circular(23),
        border:Border.all(color:active?buttonColor.withOpacity(.9):theme.primary.withOpacity(.18),width:active?1.7:1),
        boxShadow:[BoxShadow(color:glow.withOpacity(active ? .28 : .07),blurRadius:active?22:12,offset:const Offset(0,6)),
          BoxShadow(color:Colors.white.withOpacity(.035),blurRadius:2,offset:const Offset(-1,-1))],
      ),
      child:Row(children:[
        Container(width:56,height:56,decoration:BoxDecoration(
          gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:active?[Color.lerp(buttonColor,Colors.white,.30)!,buttonColor]:[theme.accent,theme.card]),
          borderRadius:BorderRadius.circular(18),border:Border.all(color:active?Colors.white.withOpacity(.4):theme.primary.withOpacity(.12)),
          boxShadow:active?[BoxShadow(color:buttonColor.withOpacity(.45),blurRadius:15,offset:const Offset(0,4))]:[]),
          child:Icon(IconData(relay.iconCodePoint,fontFamily:'MaterialIcons'),size:29,
            color:active?(buttonColor.computeLuminance()<.32?Colors.white:Colors.black87):theme.text.withOpacity(.8))),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(relay.name,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:theme.text,fontSize:16,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),
          Row(children:[Container(width:7,height:7,decoration:BoxDecoration(shape:BoxShape.circle,color:active?buttonColor:theme.text.withOpacity(.35),
            boxShadow:active?[BoxShadow(color:buttonColor.withOpacity(.8),blurRadius:7)]:[])),
            const SizedBox(width:6),Text(active?'روشن':'خاموش',style:TextStyle(color:active?buttonColor:theme.text.withOpacity(.55),fontSize:12,fontWeight:FontWeight.w700))]),
        ])),
        Switch(value:active,onChanged:enabled?onChanged:null),
      ]),
    );
  }
}
