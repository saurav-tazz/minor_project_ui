import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/widgets/buttons.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isHidden = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        child: Center(
          child: Container( // whiteCard
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),

            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Logo(size: 100,),
                  const SizedBox(height: 16,),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8,),
                  Text(
                      'Ready to challenge your friends?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),

                  const SizedBox(height: 30,),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(32),
                    ),

                    child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black87,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        tabs: [
                          Tab(text: 'Login'),
                          Tab(text: 'Register',),
                    ],
                    ),

                  ),
                  SizedBox(height: 16,),

                  SizedBox(
                    height: 300,
                    child: TabBarView(children: [
                      _Login(),
                      _Register(),
                    ]),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _Login(){
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.black45),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
                Icons.email_outlined,
              color: Colors.black45,
            ),
          ),
        ),

        const SizedBox(height: 16,),
        TextField(
          obscureText: _isHidden,
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade200,
            labelText: 'Password',
              labelStyle: TextStyle(color: Colors.black45),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
              prefixIcon: Icon(Icons.lock, color: Colors.black45,),
            suffixIcon: IconButton(
                onPressed: (){
                  setState(() {
                    _isHidden= !_isHidden;
                  });
                }
                ,
                icon: Icon(
                  _isHidden? Icons.visibility: Icons.visibility_off,
                ),
              color: Colors.black45,
            )
          ),
        ),

        const SizedBox(height: 24,),
        // SizedBox(
        //   height: 50,
        //   width: double.infinity,

          // child: ElevatedButton(
          //   onPressed: (){
          // // Navigator.pushReplacement(context,
          // //     MaterialPageRoute(builder: (context)=> const HomeScreen()),
          //     print('Logged IN');
          //
          //   },
          //    style: ElevatedButton.styleFrom(
          //       backgroundColor: Color(0xFF42A5F5),
          //       shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(16),
          //       ),
          //   ),
          //
          //   child: const Text(
          //     'Login',
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 24,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
            AppButton(
              text: "Login",
              onPressed: () {
                // print('Logged IN');
                Navigator.pushReplacementNamed(context, '/genre');
              },
              fontSize: 24,
            )

        // ),
      // ,
    ]);
  }

  Widget _Register(){
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            labelText: 'Username',
            labelStyle: TextStyle(color: Colors.black45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.person,color: Colors.black45,),
          ),
        ),
        const SizedBox(height: 24,),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.black45),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email_outlined,color: Colors.black45,),
          ),
        ),

        const SizedBox(height: 16,),
        TextField(
          obscureText: _isHidden,
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade200,
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.black45),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.lock,color: Colors.black45,),
              suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      _isHidden= !_isHidden;
                    });
                  }
                  ,
                  icon: Icon(
                    _isHidden? Icons.visibility: Icons.visibility_off,
                  ),
                color: Colors.black45,
              )
          ),
        ),

        const SizedBox(height: 24,),
        // SizedBox(
        //   width: double.infinity,
        //   height: 50,
          // child: ElevatedButton(
          //   onPressed: (){
          // // Navigator.pushReplacement(context,
          // //     MaterialPageRoute(builder: (context)=> const HomeScreen()),
          //     print('Registered');
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Color(0xFF42A5F5),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(16),
          //     ),
          //   ),
          //   child: const Text(
          //     'Register',
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 24,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),

            AppButton(
              text: "Register",
              onPressed: () {
                print('Registered');
              },
              fontSize: 24,
            ),
        // ),
      ],
    );
  }
}


