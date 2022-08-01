typedef Object? InjectorFunction(Resolver injector);

abstract class Resolver {
  Object? resolve(Type type);

  T? call<T>();
}

abstract class IProvider {
  Object? provide(Resolver resolver);
}

abstract class IInjector extends Resolver {
  void register(Type type, IProvider provider);

  void unregister(Type type, IProvider provider);
}

class Inject {
  const Inject();
}

class Injector extends IInjector {
  Map<Type, IProvider> _map = new Map<Type, IProvider>();
  Resolver? _parent;

  Injector({Resolver? parent}) : _parent = parent;

  void register(Type type, IProvider provider) {
    _map[type] = provider;
  }

  void unregister(Type type, IProvider provider) {
    _map.remove(type);
  }

  @override
  Object? resolve(Type type) {
    if (_map.containsKey(type)) {
      var resolver = _map[type];
      return resolver!.provide(this);
    } else if (_parent != null) {
      return _parent!.resolve(type);
    }
    return null;
  }

  @override
  T call<T>() {
    return resolve(T) as T;
  }
}

extension InjectorExtensions on IInjector {
  void toValue({Type? api, required Object value}) {
    this.register(api ?? value.runtimeType, new _ValueProvider(value));
  }

  void toSingleton(Type api, InjectorFunction factory) {
    this.register(api, new _SingletonProvider(factory));
  }

  void toFactory(Type api, InjectorFunction factory) {
    this.register(api, new _FactoryProvider(factory));
  }

  T? resolve<T>() {
    return this.resolve(T) as T;
  }
}

class _ValueProvider extends IProvider {
  final Object _value;

  _ValueProvider(Object value) : this._value = value;

  @override
  Object provide(Resolver resolver) {
    return _value;
  }
}

class _SingletonProvider extends IProvider {
  final InjectorFunction _func;
  late Object? _result;
  late bool _isProvided;

  _SingletonProvider(InjectorFunction func) : _func = func {
    _result = null;
    _isProvided = false;
  }

  @override
  Object? provide(Resolver resolver) {
    if (_isProvided) {
      return _result;
    }
    _isProvided = true;
    _result = _func(resolver);
    return _result;
  }
}

class _FactoryProvider extends IProvider {
  final InjectorFunction _func;

  _FactoryProvider(InjectorFunction func) : _func = func;

  @override
  Object? provide(Resolver resolver) {
    return _func(resolver);
  }
}
