import 'package:flutter/material.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/services/html_paginator.dart';

class Tp extends StatefulWidget {
  const Tp({super.key});

  @override
  State<Tp> createState() => _TpState();
}

class _TpState extends State<Tp> {
  List<Widget> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePages();
    });
  }

  Future<void> _initializePages() async {
    final size = MediaQuery.of(context).size;
    final pageHeight = size.height - MediaQuery.of(context).padding.vertical;

    final pages = await HtmlPaginator.paginateHtml(
      htmlContent: htmlString,
      context: context,
      pageHeight: pageHeight,
      pageWidth: size.width,
    );

    if (mounted) {
      setState(() {
        _pages = pages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PageFlipWidget(
                children: _pages,
              ),
      ),
    );
  }
}

String htmlString = '''
  <html lang="en">
<head>
    <title>Large HTML File</title>
</head>
<body>
    <h1>Large HTML File</h1>
    <p>This is a large HTML file with repetitive sections for testing purposes.</p>
    <div>
        <div id="section-1">
            <h2>Section 1</h2>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum.</p>
        </div>
        <div id="section-2">
            <h2>Section 2</h2>
            <p>Curabitur ut ipsum ac libero malesuada tristique. Nulla facilisi. Ut fringilla neque non risus luctus, a pulvinar justo vehicula.</p>
        </div>
        <div id="section-3">
            <h2>Section 3</h2>
            <p>Integer eu augue id orci gravida consequat. Donec congue, massa vitae interdum auctor, felis augue bibendum nulla, et faucibus ex magna nec est.</p>
        </div>
        <div id="section-4">
            <h2>Section 4</h2>
            <p>Proin imperdiet turpis non orci posuere, non sodales ex aliquam. Morbi at justo a nulla fermentum bibendum.</p>
        </div>
        <div id="section-5">
            <h2>Section 5</h2>
            <p>Phasellus et velit id mauris convallis interdum. Fusce efficitur sapien in velit eleifend, non aliquet lorem pellentesque.</p>
        </div>

        <div id="section-1000">
            <h2>Section 1000</h2>
            <p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Integer viverra a turpis nec fringilla.</p>
        </div>
    </div>

        <div id="section-1001">
            <h2>Section 1001</h2>
            <p>Suspendisse potenti. Ut pretium ultricies odio, quis convallis justo aliquet id. Quisque a enim ac urna fermentum volutpat.</p>
        </div>
        <div id="section-1002">
            <h2>Section 1002</h2>
            <p>Donec pulvinar ligula nec enim auctor, quis interdum tortor consequat. In a lorem vitae nisl vulputate faucibus.</p>
        </div>
        <div id="section-1003">
            <h2>Section 1003</h2>
            <p>Morbi et felis at quam tincidunt efficitur. Integer congue lorem vel justo viverra, sit amet tincidunt mauris dapibus.</p>
        </div>
        <div id="section-1004">
            <h2>Section 1004</h2>
            <p>Ut id felis vel sapien pretium gravida. Cras pellentesque orci ac nisi feugiat, at tincidunt elit interdum.</p>
        </div>
        <div id="section-1005">
            <h2>Section 1005</h2>
            <p>Nulla vel nunc sed magna efficitur porttitor. Suspendisse rutrum, justo in pellentesque feugiat, justo mi hendrerit sapien, eget luctus nisi lectus ut ante.</p>
        </div>
        <div id="section-1006">
            <h2>Section 1006</h2>
            <p>Vestibulum convallis tortor ac mauris dictum, ac condimentum sapien dictum. Fusce scelerisque nisi at augue malesuada, vitae fringilla metus convallis.</p>
        </div>
        <div id="section-1007">
            <h2>Section 1007</h2>
            <p>Praesent a lacus ut neque tristique porttitor. Integer id orci sit amet risus mollis vestibulum.</p>
        </div>
        <div id="section-1008">
            <h2>Section 1008</h2>
            <p>Aliquam erat volutpat. Mauris posuere libero nec lacinia tincidunt. Duis consectetur urna ut lectus venenatis aliquet.</p>
        </div>
        <div id="section-1009">
            <h2>Section 1009</h2>
            <p>Phasellus facilisis nisi eget magna tempor fringilla. Nunc ut orci at magna porttitor malesuada.</p>
        </div>
        <div id="section-1010">
            <h2>Section 1010</h2>
            <p>Etiam et ligula sed magna ultricies scelerisque. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.</p>
        </div>
        <div id="section-1011">
            <h2>Section 1011</h2>
            <p>Cras mattis nulla id purus porttitor, non auctor urna efficitur. Vestibulum vehicula quam in velit viverra, quis luctus est aliquam.</p>
        </div>
        <div id="section-1012">
            <h2>Section 1012</h2>
            <p>Vivamus sodales est in erat auctor, nec pellentesque ex interdum. Integer quis lorem nec velit pharetra suscipit.</p>
        </div>
        <div id="section-1013">
            <h2>Section 1013</h2>
            <p>Fusce pharetra orci sit amet magna bibendum, nec dignissim est consequat. Maecenas malesuada odio ac risus cursus, in interdum sem aliquet.</p>
        </div>
        <div id="section-1014">
            <h2>Section 1014</h2>
            <p>Proin consequat magna at augue efficitur, ac viverra elit consectetur. Curabitur non libero nec odio placerat auctor vel id nulla.</p>
        </div>
        <div id="section-1015">
            <h2>Section 1015</h2>
            <p>Nullam a enim a felis congue ultrices. Praesent faucibus, augue et tincidunt fringilla, arcu nulla tincidunt justo, nec lacinia magna arcu eget dolor.</p>
        </div>

        <!-- Adding 20 more paragraphs with random text -->
        <div id="section-1016">
            <h2>Section 1016</h2>
            <p>Aliquam nec urna eget velit facilisis faucibus. Nulla non urna ut urna fringilla mollis id at odio.</p>
        </div>
        <div id="section-1017">
            <h2>Section 1017</h2>
            <p>Pellentesque vehicula dolor ac libero laoreet, id fermentum libero blandit. Fusce vehicula dapibus metus.</p>
        </div>
        <div id="section-1018">
            <h2>Section 1018</h2>
            <p>Nam congue tortor sit amet magna euismod, eget congue arcu tincidunt. Nulla ac elit eu metus malesuada rhoncus.</p>
        </div>
        <div id="section-1019">
            <h2>Section 1019</h2>
            <p>Curabitur tincidunt dui eu enim mollis, sed vehicula erat tincidunt. Vivamus at quam eu justo feugiat tincidunt.</p>
        </div>
        <div id="section-1020">
            <h2>Section 1020</h2>
            <p>Etiam eget elit vel velit blandit sodales. Duis vehicula tortor ac odio cursus, eget pellentesque lorem dictum.</p>
        </div>
        <div id="section-1021">
            <h2>Section 1021</h2>
            <p>Praesent ac lacus eget metus luctus scelerisque. Proin condimentum lectus ut urna ultricies, quis hendrerit magna tincidunt.</p>
        </div>
        <div id="section-1022">
            <h2>Section 1022</h2>
            <p>Morbi dapibus nulla in metus facilisis, a dapibus libero suscipit. Donec nec odio auctor, volutpat felis at, dictum purus.</p>
        </div>
        <div id="section-1023">
            <h2>Section 1023</h2>
            <p>Sed sit amet lectus id nisl egestas accumsan. Duis efficitur velit non lectus pharetra, ut venenatis ligula cursus.</p>
        </div>
</body>
</html>
''';
