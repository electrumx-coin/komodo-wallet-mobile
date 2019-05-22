import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/widgets/primary_button.dart';

class BlocLoginPage extends StatefulWidget {
  @override
  _BlocLoginPageState createState() => _BlocLoginPageState();
}

class _BlocLoginPageState extends State<BlocLoginPage> {
  TextEditingController controllerSeed = new TextEditingController();
  bool _isButtonDisabled = false;
  bool _isLogin;

  @override
  void initState() {
    _isLogin = false;
    _isButtonDisabled = true;
    super.initState();
  }

  @override
  void dispose() {
    controllerSeed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context).login[0].toUpperCase()}${AppLocalizations.of(context).login.substring(1)}'),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(
        children: <Widget>[
          _buildTitle(),
          _buildInputSeed(),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  _buildTitle() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 56,
        ),
        Center(
          child: Text(
            AppLocalizations.of(context).enterSeedPhrase,
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 56,
        ),
      ],
    );
  }

  _buildInputSeed() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controllerSeed,
        onChanged: (str) {
          print(str.length);
          if (str.length == 0) {
            setState(() {
              _isButtonDisabled = true;
            });
          } else {
            setState(() {
              _isButtonDisabled = false;
            });
          }
        },
        autocorrect: false,
        keyboardType: TextInputType.multiline,
        obscureText: true,
        enableInteractiveSelection: true,
        maxLines: null,
        style: Theme.of(context).textTheme.body1,
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColorLight)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).accentColor)),
            hintStyle: Theme.of(context).textTheme.body2,
            labelStyle: Theme.of(context).textTheme.body1,
            hintText: AppLocalizations.of(context).exampleHintSeed,
            labelText: null),
      ),
    );
  }

  _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        height: 50,
        child: _isLogin
            ? Center(child: CircularProgressIndicator())
            : 
            PrimaryButton(
              text: AppLocalizations.of(context).confirm,
              onPressed: _isButtonDisabled ? null : _onLoginPressed
            ),
      ),
    );
  }

  _onLoginPressed() {
    setState(() {
      _isButtonDisabled = true;
      _isLogin = true;
    });
    FocusScope.of(context).requestFocus(new FocusNode());

    authBloc.loginUI(true, controllerSeed.text.toString()).then((onValue) {
      Navigator.pop(context);
    }).then((_) {
      setState(() {
        _isLogin = false;
      });
    });
  }
}
