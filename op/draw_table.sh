#!/bin/bash
#############################################################################
# 改编人：猪猪侠
# Test On: CentOS 7
# 原作者：banemon
# 原Git : https://gitee.com/banemon/linux_sh_script
# 原地址: https://zhuanlan.zhihu.com/p/144802861
#############################################################################


F_HELP()
{
    echo "
    用途：将文件以表格的形式输出
    依赖：
    注意：
        * 默认使用【\\t】作为表格分隔符，如果是其他，请自行指定，否则会出错；
        * 表格连标题一起至少2行，至少有一行有2个及以上的字段，否则出错。
        * 输入命令时，参数顺序不分先后
    用法：
        $0 [-h|--help]
        $0 <-d|--delimeter {表格分隔符}>  <-s|--style [预定义样式 | {%自定义样式}]>  <-c|--color [预定义颜色前景,背景,文字 | {%自定义颜色}]>  < {文件名}
        echo -e \"AB\\na\\tb ......\" | $0 <-d|--delimeter {表格分隔符}>  <-s|--style [预定义样式 | {%自定义样式}]>  <-c|--color [预定义颜色前景,背景,文字 | {%自定义颜色}]>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -d|--delimeter ：定义表格列之间的分隔符，默认为【\\t】
        -s|--style     ：定义表格样式，默认为【+++++++++,---|||】
                         # 前9位表示表格边框，第10位表示填充字符，第11-13 表示行的上、中、下分隔符，第14-16表示列的左、中、右分隔符
                         s0  :'                '        s8  : └─┘│┼│┌─┐ ─ ─│ │
                         s1  : └┴┘├┼┤┌┬┐ ───│││         s9  : ╚╩╝╠╬╣╔╦╗ ═ ═║ ║
                         s2  : └─┘│┼│┌─┐ ───│││         s10 : ╚═╝║╬║╔═╗ ═ ═║ ║
                         s3  : ╚╩╝╠╬╣╔╦╗ ═══║║║         s11 : ╙╨╜╟╫╢╓╥╖ ─ ─║ ║
                         s4  : ╚═╝║╬║╔═╗ ═══║║║         s12 : ╘╧╛╞╪╡╒╤╕ ═ ═│ │
                         s5  : ╙╨╜╟╫╢╓╥╖ ───║║║         s13 : ╘╧╛╞╪╡╒╤╕ ═ ═│ │
                         s6  : ╘╧╛╞╪╡╒╤╕ ═══│││         s14 : ╚╩╝╠╬╣╔╦╗ ───│││
                         s7  : └┴┘├┼┤┌┬┐ ─ ─│ │         s15 : +++++++++ ---|||
                         # 自定义
                         以【%】开头，比如：【%123456789 abcABC】
                         #
        -c|--color     ：定义表格颜色，默认为【@4,@8,@4】，含义为【拐角颜色,文字颜色,表格颜色】，或理解为【背景,前景,表格】颜色
                         # 颜色定义：
                         @1|@black         @5|@blue
                         @2|@red           @6|@purple
                         @3|@green         @7|@cyan
                         @4|@yellow        @8|@white
                         # 组合颜色
                         1  : @2,@8,@3
                         2  : @2,@8,@5
                         3  : @2,@5,@8
    示例：
        # 表格输入
        $0  < 文件1                      #--- 将【文件1】输出为表格，所有皆为默认
        echo -e "AB\\na\\tb" | bash $0       #--- 将echo内容输出为表格，所有皆为默认
        # 分隔符
        $0        < 文件1                #--- 使用默认分隔符
        $0  -t :  < 文件1                #--- 使用默认分隔符【:】
        $0  -t |  < 文件1                #--- 使用默认分隔符【|】
        # 样式
        $0  -s s15                  < 文件1       #--- 使用表格样式【s15】
        $0  -s '%123456789 abcABC'  < 文件1       #--- 使用自定义表格样式【%123456789 abcABC】
        # 颜色
        $0  -c @red,@blue,@white              < 文件1       #--- 使用背景前景表格颜色为【红,蓝,外】
        $0  -c @2,@5,@8                       < 文件1       #--- 同上
        $0  -c 3                              < 文件1       #--- 同上
        $0  -c \\033[31m,\\033[34m,\\033[29m     < 文件1       #--- 同上
        #
        $0  -t :  -s s15                        < 文件1     #--- 使用【:】作为分隔符，【s15】为表格样式
        $0  -t :          -c @2,@5,@8           < 文件1     #--- 使用【:】作为分隔符，【红,蓝,外】为表格颜色
        $0        -s s15  -c @red,@blue,@white  < 文件1     #--- 使用【s15】为表格样式，【红,蓝,外】为表格颜色
        $0  -t :  -s s15  -c @red,@blue,@white  < 文件1     #--- 使用【:】作为分隔符，【s15】为表格样式，【红,蓝,外】为表格颜色
"
}



# 参数检查
TEMP=`getopt -o hd:s:c:  -l help,delimeter:,style:,color: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"


#
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -d|--delimeter)
            TAB_DELIMETER="$2"
            shift 2
            ;;
        -s|--style)
            style="$2"
            shift 2
            ;;
        -c|--color)
            color="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
            exit 1
            ;;
    esac
done



# 表格样式style
case "${style}" in
    # tbs包含16个符号, 每个符号表示的含义如下:
    # 1 2 3 4 5 6 7 8 9 10       11      12      13       14      15      16
    # 1 2 3 4 5 6 7 8 9 txt_empt top_row mid_row btm_row left_col mid_col right_col
    s0)  tbs="                ";;
    s1)  tbs="└┴┘├┼┤┌┬┐ ───│││";;
    s2)  tbs="└─┘│┼│┌─┐ ───│││";;
    s3)  tbs="╚╩╝╠╬╣╔╦╗ ═══║║║";;
    s4)  tbs="╚═╝║╬║╔═╗ ═══║║║";;
    s5)  tbs="╙╨╜╟╫╢╓╥╖ ───║║║";;
    s6)  tbs="╘╧╛╞╪╡╒╤╕ ═══│││";;
    s7)  tbs="└┴┘├┼┤┌┬┐ ─ ─│ │";;
    s8)  tbs="└─┘│┼│┌─┐ ─ ─│ │";;
    s9)  tbs="╚╩╝╠╬╣╔╦╗ ═ ═║ ║";;
    s10) tbs="╚═╝║╬║╔═╗ ═ ═║ ║";;
    s11) tbs="╙╨╜╟╫╢╓╥╖ ─ ─║ ║";;
    s12) tbs="╘╧╛╞╪╡╒╤╕ ═ ═│ │";;
    s13) tbs="╘╧╛╞╪╡╒╤╕ ═ ═│ │";;
    s14) tbs="╚╩╝╠╬╣╔╦╗ ───│││";;
    s15) tbs="+++++++++ ---|||";;
    # 自定义表格边框：需要用"%"开头，前9位表示表格边框，第10位表示填充字符，第11-13 表示行的上、中、下分隔符，第14-16表示列的左、中、右分隔符
    # ${string/substring/replacement}: 使用$replacement, 来代替第一个匹配的$substring, 这里是去掉开头的%, 另外由于%是特殊字符需要加上双引号(或者反斜杠)
    "%"*) tbs="${style/"%"/}";;
    # 等价于: \%*) tbs="${style/\%/}";;
    h*)
        # -e 参数激活转移字符, 比如\t表示制表符
        echo -e '
\t [  ---   HELP  ---  ]
\t command : sh draw_table.sh -d [delimeter] -s [style] -c [colors] < <file>
\t    pipo : echo -e A\\tB\\na\\tb | draw_table.sh -d [delimeter] -s [style] -c [colors]
\t [style] : input 16 characters
\t           1~9 is Num. keypad as table,10 is not used
\t           11~13 are up,middle,down in a row
\t           14~16 are left,middle,right in a column
\t
\t         s0  :
\t         s1  :└┴┘├┼┤┌┬┐ ───│││         s9  :╚╩╝╠╬╣╔╦╗ ═ ═║ ║
\t         s2  :└─┘│┼│┌─┐ ───│││         s10 :╚═╝║╬║╔═╗ ═ ═║ ║
\t         s3  :╚╩╝╠╬╣╔╦╗ ═══║║║         s11 :╙╨╜╟╫╢╓╥╖ ─ ─║ ║
\t         s4  :╚═╝║╬║╔═╗ ═══║║║         s12 :╘╧╛╞╪╡╒╤╕ ═ ═│ │
\t         s5  :╙╨╜╟╫╢╓╥╖ ───║║║         s13 :╘╧╛╞╪╡╒╤╕ ═ ═│ │
\t         s6  :╘╧╛╞╪╡╒╤╕ ═══│││         s14 :╚╩╝╠╬╣╔╦╗ ───│││
\t         s7  :└┴┘├┼┤┌┬┐ ─ ─│ │         s15 :+++++++++ ---|||
\t         s8  :└─┘│┼│┌─┐ ─ ─│ │
\t
\t [colors]: input a list,like "@3,@4,@8" sames "@green,@yellow,@white"
\t           It set color,table cross ,font ,middle. Or \\033[xxm .
\t           And support custom color set  every characters of sytle
\t           Like "\\033[30m,@red,@yellow,,,,,,,,,,,,," sum 16.
\t
\t          @1|@black         @5|@blue
\t          @2|@red           @6|@purple
\t          @3|@green         @7|@cyan
\t          @4|@yellow        @8|@white
        '
        exit
        ;;
esac
# 当没有参数时, 设定tbs的默认值
tbs="${tbs:-"+++++++++,---|||"}"


# 颜色
case "$color" in
    # 1~3可用于设置自己喜欢的自定义样式, 设置${color}的值即可
    1) colors="@2,@8,@3" ;;
    2) colors="@2,@8,@5" ;;
    3) colors="@2,@5,@8" ;;
    #"-"*|"\033"*)
    "@"*|"\033"*)
        # 3位数标,词
        colors="$color"
        ;;
    "%"*) :
        # %号开头的全自定义
        colors="${color/"%"/}"
        ;;
esac
# 设置colors默认值
colors="${colors:-"@4,@8,@4"}"


# 设置分隔符默认值
TAB_DELIMETER=${TAB_DELIMETER:-'\t'}


# 主体函数
gawk -F "${TAB_DELIMETER}" \
    -v table_s="${tbs}" \
    -v color_s="${colors}" \
    'BEGIN{
    }{
        # ------------------------------------------遍历每行记录全局变量------------------------------------------
        # cols_len[NF]: 存储了每一列的最大长度, 每列最大长度等于该列最长的元素的长度
        # rows[NR][NF]: 将文件的每行每列的数据记录到rows二维数组中
        # rows[NR][0]: 第0列存储前一行和后一行的列数, 用于确定当行的表格样式
        # max_single_col_length: 单列行的最大长度
        # ps: 由于单列是直接合并整行的单元格, 为图表美观(防止cols_len[1]因为某些特长的单列而增长), 单独记录单列的最大长度

        # 计算单列行的最大长度
        if (NF == 1) {
            max_single_col_length = max_single_col_length < super_length($1) ? super_length($1) : max_single_col_length
            rows[NR][1] = $1
        } else { # 非单列行更新每一列的最大长度
            for(i=1; i<=NF; i++){
                cols_len[i]=cols_len[i] < super_length($i) ? super_length($i) : cols_len[i]
                rows[NR][i]=$i
            }
        }

        # 前后行状态
        if (NR == 1) {PrevNF=0}
        # 每行第0列存储前一行和当前行的列数, 用于确定当行的表格样式
        rows[NR][0] = PrevNF "," NF
        PrevNF=NF

    }END{
        # ------------------------------------------colors变量着色, 生成colors和tbs变量------------------------------------------
        # 构建颜色向量: colors, 长度为16
        color_sum = split(color_s,clr_id,",")
        if (color_sum == 3){ # 简易自定义模式: 传入三种颜色
            for (i=1; i<=3; i++) {
                #if (color_s ~ "-") {
                if (color_s ~ "@") {
                    clr_id[i] = color_var(clr_id[i])
                }
            }
            # 组建色表: 三种颜色构造colors向量
            for (i=1; i<=16; i++) {
                if (i < 10) {
                    colors[i] = clr_id[1]
                } else if (i == 10){
                    colors[i] = clr_id[2]
                } else if (i > 10){
                    colors[i] = clr_id[3]
                }
            }
        } else if (color_sum == 16){ # 全自定义模式: 传入16种颜色
            for (i=1; i<=16; i++){
                #if(color_s ~ "-"){
                if(color_s ~ "@"){
                    clr_id[i] = color_var(clr_id[i])
                }
                colors[i] = clr_id[i]
            }
        }

        # 设置颜色变量
        clr_end = "\033[0m"   # shell着色的尾部标识
        clr_font = colors[10] # 第10位制表符的颜色, 也就是单元格内填充字符的颜色

        # 构建已着色的制表符向量: tbs, 长度16
        for (i=1; i<=length(table_s); i++){
            if(colors[i]=="")
                tbs[i] = substr(table_s, i, 1) # 获取第i个制表符
            else
                tbs[i] = colors[i] substr(table_s,i,1) clr_end # 给制表符着色, 例如红色 `\033[31m制表符\033[0m`
            fi
        }

        # ------------------------------------------如果单列长度大于非单列最大行长度则调整各列长度------------------------------------------
        max_line_len = 0 # 统计非单列的最大行长度
        for (i=1; i<=length(cols_len); i++) {
            max_line_len = max_line_len + cols_len[i] + 2 # 每列需要包含2个空格, 防止内容和制表符紧挨着
        }
        max_line_len = max_line_len + length(cols_len) - 1 # 多列的行最大总长度需要包含每列之间的制表符个数(列数 -1)

        # 如果单列最大总长度大于多列的行最大总长度时, 需要把超出的部分平均分给每列, 保证图表美观
        diff_length = max_single_col_length + 2 - max_line_len
        if (diff_length > 0) {
            for(j=1; j<=diff_length; j++){
                i = (j - 1) % length(cols_len) + 1
                cols_len[i] = cols_len[i] + 1
            }
            # 由于增加了每列长度, 故需要调整单列最大行长度
            # max_line_len = max_single_col_length + 2
        } else { # 如果单列最大总长度小于行的最大总长度, 那么单列长度要和最大行总长度保持一致
            max_single_col_length = max_line_len - 2
        }

        # ------------------------------------------预存所有的表格线, 减少不必要的重复计算------------------------------------------
        title_top = line_val("title_top")
        title_mid = line_val("title_mid")
        title_btm_mid = line_val("title_btm_mid")
        title_top_mid = line_val("title_top_mid")
        title_btm = line_val("title_btm")
        top = line_val("top")
        mid = line_val("mid")
        btm = line_val("btm")
        # debug
        # print "title_top:    " title_top "\n"
        # pring "title_mid:    " title_mid "\n"
        # print "title_btm_mid:" title_btm_mid "\n"
        # print "title_top_mid:" title_top_mid" \n"
        # print "title_btm:    " title_btm" \n"
        # print "top:          " top" \n"
        # print "mid:          " mid" \n"
        # print "btm:          " btm" \n"

        # ------------------------------------------绘制表格------------------------------------------
        row_num = length(rows)
        for(i=1; i<=row_num; i++){
            # 解析出前一行和当前行的列数
            split(rows[i][0], col_num_list, ",")
            prev_col_num = int(col_num_list[1])
            curr_col_num = int(col_num_list[2])

            # 绘制首行
            if (i==1 && prev_col_num == 0) {
                if (curr_col_num <= 1) {
                    # 单列
                    print title_top
                    print line_val("title_txt", rows[i][1], max_single_col_length)

                } else if (curr_col_num >= 2) {
                    # 多列
                    print top
                    print line_val("txt", rows[i])
                }
            } else if (prev_col_num <=1 ) {
                # 前一行为单列时
                if (curr_col_num <=1 ) {
                    # 单列
                    print title_mid
                    print line_val("title_txt", rows[i][1], max_single_col_length)
                } else if (curr_col_num >= 2) {
                    # 多列
                    print title_btm_mid
                    print line_val("txt", rows[i])
                }

            }else if (prev_col_num >= 2) {
                # 前一行为多列时
                if (curr_col_num <= 1) {
                    # 单列
                    print title_top_mid
                    print line_val("title_txt", rows[i][1], max_single_col_length)

                } else if (curr_col_num >= 2) {
                    # 多列
                    print mid
                    print line_val("txt", rows[i])
                }
            }
            # 表格底边
            if (i == row_num && curr_col_num <= 1) {
                # 尾行单列时
                print title_btm
            } else if (i == row_num && curr_col_num >= 2){
                # 尾行多列时
                print btm
            }
        }
    }

    # 返回字符串的长度, 支持中文等双字节字符
    # eg: 内置函数length("中文")返回2, super_length("中文")返回4
    function super_length(txt){
        leng_base = length(txt);
        leng_plus = gsub(/[^\x00-\xff]/, "x", txt) # 返回Ascii码大于255的字符匹配个数
        return leng_base + leng_plus
    }

#    # color_var函数: 解析形如"-n"开头的颜色配置
#    function color_var(color){
#        if(color=="-1" ||color=="-black"){
#            n=30
#        }else if(color=="-2" || color=="-red"){
#            n=31
#        }else if(color=="-3" || color=="-green"){
#            n=32
#        }else if(color=="-4" || color=="-yellow"){
#            n=33
#        }else if(color=="-5" || color=="-blue"){
#            n=34
#        }else if(color=="-6" || color=="-purple"){
#            n=35
#        }else if(color=="-7" || color=="-cyan"){
#            n=36
#        }else if(color=="-8" || color=="-white"){
#            n=37
#        }else if(color=="-0" || color=="-reset"){
#            n=0
#        }else{
#            n=0
#        }
#        return "\033[" n "m"
#    }
    # color_var函数: 解析形如"-n"开头的颜色配置
    function color_var(color){
        if(color=="@1" ||color=="@black"){
            n=30
        }else if(color=="@2" || color=="@red"){
            n=31
        }else if(color=="@3" || color=="@green"){
            n=32
        }else if(color=="@4" || color=="@yellow"){
            n=33
        }else if(color=="@5" || color=="@blue"){
            n=34
        }else if(color=="@6" || color=="@purple"){
            n=35
        }else if(color=="@7" || color=="@cyan"){
            n=36
        }else if(color=="@8" || color=="@white"){
            n=37
        }else if(color=="@0" || color=="@reset"){
            n=0
        }else{
            n=0
        }
        return "\033[" n "m"
    }

    # ------------------------------------------生成绘制内容的函数------------------------------------------
    # 参数: part绘制的位置; txt绘制的文本内容; cell_lens绘制的单元格长度
    # eg: tbs为已着色的制表符 ╚ ╩ ╝ ╠ ╬ ╣ ╔ ╦ ╗ , ═ ═ ═ ║ ║ ║
    # TODO: cell_len, line, i这三个参数的意义何在, awk的特殊用法?
    function line_val(part, txt, cell_lens, cell_len, line, i) {
        # 更新本次行标
        if (part=="top") {
            tbs_l=tbs[7]
            tbs_m=tbs[8]
            tbs_r=tbs[9]
            tbs_b=tbs[11]
        } else if (part=="mid") {
            tbs_l=tbs[4]
            tbs_m=tbs[5]
            tbs_r=tbs[6]
            tbs_b=tbs[12]
        } else if (part=="txt") { # tbs[10]为填充字符, 用于填充单元格内的空格
            tbs_l=tbs[14] tbs[10]
            tbs_m=tbs[10] tbs[15] tbs[10]
            tbs_r=tbs[10] tbs[16]
            tbs_b=tbs[10]
        } else if (part=="btm"){
            tbs_l=tbs[1]
            tbs_m=tbs[2]
            tbs_r=tbs[3]
            tbs_b=tbs[13]
        } else if (part=="title_top"){
            tbs_l=tbs[7]
            tbs_m=tbs[11]
            tbs_r=tbs[9]
            tbs_b=tbs[11]
        } else if (part=="title_top_mid"){
            tbs_l=tbs[4]
            tbs_m=tbs[2]
            tbs_r=tbs[6]
            tbs_b=tbs[12]
        } else if (part=="title_mid"){
            tbs_l=tbs[4]
            tbs_m=tbs[12]
            tbs_r=tbs[6]
            tbs_b=tbs[12]
        } else if (part=="title_txt"){
            tbs_l=tbs[14] tbs[10]
            tbs_m=tbs[10] tbs[15] tbs[10]
            tbs_r=tbs[10] tbs[16]
            tbs_b=tbs[10]
        } else if (part=="title_btm"){
            tbs_l=tbs[1]
            tbs_m=tbs[13]
            tbs_r=tbs[3]
            tbs_b=tbs[13]
        } else if (part=="title_btm_mid"){
            tbs_l=tbs[4]
            tbs_m=tbs[8]
            tbs_r=tbs[6]
            tbs_b=tbs[12]
        }

        # title行只有一列文本
        if (part == "title_txt") {
            cols_count=1
        } else {
            cols_count = length(cols_len)
        }

        # 遍历该行所有列, 构造改行的内容
        line_content = ""

        # 对于一行内的每一个单元格, 计算单元格文本cell_txt 和 对应的空白字符填充数fill_len
        for (i=1; i<=cols_count; i++) {
            if (part == "txt") {
                # 多列左对齐
                cell_txt = txt[i]
                fill_len = cols_len[i] - super_length(cell_txt)
            }else if(part=="title_txt"){
                # 单列居中
                cell_txt = txt
                fill_len = (cell_lens - super_length(cell_txt)) / 2
                is_need_fix = (cell_lens - super_length(cell_txt)) % 2 # 如果填充字符长度非偶数则需要fix
            } else {
                cell_txt = ""
                fill_len = cols_len[i] + 2
            }

            # 单元格文本着色
            cell_txt = clr_font cell_txt clr_end

            # 单元格内空白补全
            if (part == "title_txt") {
                # 单列居中, 在单元格文本两侧补全空格字符
                for (cell_len=1; cell_len <= fill_len; cell_len++) {
                    cell_txt = tbs_b cell_txt tbs_b
                }
                # 单列非偶长度补全
                if (is_need_fix == 1) {
                    cell_txt = cell_txt " "
                }
            }else{
                # 多列左对齐
                for (cell_len=1; cell_len<=fill_len; cell_len++) {
                    cell_txt = cell_txt tbs_b
                }
            }
            # 首格
            if (i == 1) {
                line_content = line_content cell_txt
            } else {
                # 中格
                line_content = line_content tbs_m cell_txt
            }
            # 尾格
            if ( i == cols_count ) {
                line_content = line_content tbs_r
            }
        }
        # 返回行: tbs_l表示最左侧的表格样式, line_content表示该行的内容
        return tbs_l line_content
    }
    '


