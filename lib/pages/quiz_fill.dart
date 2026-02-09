import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class QuizFill extends StatefulWidget {
  const QuizFill({super.key}); 

  @override
  State<QuizFill> createState() => _QuizFillState(); 
}


class _QuizFillState extends State<QuizFill> {
  final supabase = Supabase.instance.client; 

  late final String quizBackgroundUrl; 

  late List<Map<String, dynamic>> questions;
  late final Future<List<Map<String, dynamic>>> quizFuture; 

  @override
  void initState(){
    super.initState(); 

    quizFuture = fetchQuizData(); 

    quizBackgroundUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/QuizFill-Background.png'); 
  }

  Future<List<Map<String, dynamic>>> fetchQuizData() async {
    final res = await supabase.rpc(
      'get_random_quiz_questions',
      params: {
        'quiz_uuid': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'question_limit': 10,
      },
    );

    questions = List<Map<String, dynamic>>.from(res);
    return questions; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white, 
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: quizFuture, 
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(child: CircularProgressIndicator()); 
            }
            if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString())); 
            }
            if(snapshot.hasError || !snapshot.hasData){
              return const Center(
                child: Text('Gagal memuat data kuis'),
              ); 
            }

            final quizData = snapshot.data!; 

            if(quizData.isEmpty){
              return const Center(
                child: Text('Soal tidak ditemukan!'),
              );
            }

            return BuildQuizUI(
              quizData: quizData, 
              total: questions.length, 
              quizBackgroundUrl: quizBackgroundUrl
            );
          }
        ),
    ); 
  }
}

class BuildQuizUI extends StatefulWidget {
  final List<dynamic> quizData; 
  final int total; 
  final String quizBackgroundUrl; 

  const BuildQuizUI({
    super.key, 
    required this.quizData, 
    required this.total, 
    required this.quizBackgroundUrl
  }); 

  @override
  State<BuildQuizUI> createState ()=> _BuildQuizState(); 
}

class _BuildQuizState extends State<BuildQuizUI> {
  int currentIndex = 0; 

  @override
  Widget build(BuildContext context){

    final question = widget.quizData[currentIndex]; 
    final String questionText = question['question_text'];
    final int timeLimit = question['time_limit'];
    final List<dynamic> choices = question['quiz_choices'] ?? []; 
    final String quizBackgroundUrl = widget.quizBackgroundUrl; 

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                color: const Color.fromRGBO(217, 246, 252, 1),
              ), 

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 260,
                child: Container(
                  padding: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    
                    image: DecorationImage(
                      image: NetworkImage(quizBackgroundUrl), 
                      fit: BoxFit.cover
                    ),

                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40), 
                      bottomRight: Radius.circular(40)
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                )
              ), 

              const FrostedGlass(),

              Positioned(
                top: 150,
                left: 20, 
                right: 20, 
                child: ProgressAndQuestionCard(
                  questionText: questionText, 
                  currentIndex: currentIndex
                ),
              ), 

              Positioned(
                top: 105, 
                left: 20, 
                right: 20, 
                child: Align(
                  alignment: Alignment.center, 
                  child: QuestionNumber(),
                )
              ), 


              Positioned(
                top: 370, 
                left: 20, 
                right: 20, 
                child: ChoiceCard(
                  choices: choices, 
                ),
              )
            ],
          );
        }
      ),
    ); 
  }
}

class FrostedGlass extends StatelessWidget {
  const FrostedGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.75),
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressAndQuestionCard extends StatelessWidget{
  final String questionText; 
  final int currentIndex; 

  const ProgressAndQuestionCard({
    super.key, 
    required this.questionText, 
    required this.currentIndex
  }); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190, 
      width: double.infinity, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.15), 
          offset: const Offset(0, 4), 
          blurRadius: 8
        )]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          const SizedBox(height: 60,), 
          
          Text('Soal No. ${currentIndex + 1}/10', style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w400,
            fontFamily: "Afacad", 
            color: Color.fromRGBO(118, 181, 193, 1)
            )
          ),

          const SizedBox(height: 10,), 

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20), 
            child: Text(questionText, textAlign: TextAlign.center, style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w400,
              color: Colors.black
              )
            ),
          )

        ],
      ),
    ); 
  }
}

class QuestionNumber extends StatelessWidget {
  const QuestionNumber({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 90, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(90), 
        color: const Color.fromRGBO(217, 246, 252, 1)
      ),
      child: Stack(
        alignment: Alignment.center, 
        children: [
          SizedBox(
            height: 70, 
            width: 70, 
            child: CircularProgressIndicator(
              value: 0.3, 
              strokeWidth: 5, 
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(
                Color.fromRGBO(63, 68, 102, 1)
              ),
            ), 
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '25',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(63, 68, 102, 1), 
            ),
          ),
        ],
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final List<dynamic> choices;  
  
  const ChoiceCard({
    super.key, 
    required this.choices
  }); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320, 
      width: double.infinity, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          )
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(), 
        itemCount: choices.length, 
        separatorBuilder: (_, __) => const SizedBox(height: 12,), 
        itemBuilder: (context, index) {
          return ChoiceTile(
            text: choices[index]['choice_text'], 
          ); 
        }
      )
    );
  }
}

class ChoiceTile extends StatelessWidget {
  final String text; 

  const ChoiceTile({
    super.key, 
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      height: 60, 
      decoration: BoxDecoration(
        color: Color.fromRGBO(118, 181, 193, 1), 
        borderRadius: BorderRadius.circular(10) 
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(5), 
        child: Container(
          width: double.infinity, 
          height: 50, 
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(10) 
          ),
          child: Text(text, softWrap: true, style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w400,
            fontFamily: "Afacad", 
            color: Colors.black
          ),),
        ),
      ),
    ); 
  }
}