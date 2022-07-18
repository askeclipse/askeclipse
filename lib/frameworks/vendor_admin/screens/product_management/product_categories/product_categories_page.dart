import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../../common/enums/load_state.dart';
import '../../../../../models/entities/index.dart';
import '../../../models/category_model.dart';
import '../widgets/category_checkbox.dart';

class CategoriesPage extends StatefulWidget {
  final String? parentId;
  final List<Category> includedCategories;
  final Function(Category? cat) onCallback;
  final Function(Category cat) onUpdate;
  const CategoriesPage(
      {Key? key,
      this.parentId,
      required this.onCallback,
      required this.onUpdate,
      required this.includedCategories})
      : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _controller = RefreshController();

  List<Category> cats = [];

  @override
  void initState() {
    final model = Provider.of<VendorAdminCategoryModel>(context, listen: false);
    for (var cat in model.categories) {
      if (cat.parent == widget.parentId) {
        cats.add(cat);
      }
    }
    if (cats.length % model.perPage == 0) {
      model.getSubCategories(widget.parentId ?? '0', cats.length);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorAdminCategoryModel>(
      builder: (_, model, __) => SmartRefresher(
        controller: _controller,
        onLoading: () async {
          if (cats.length % model.perPage != 0) {
            return;
          }
          final list = await model.getSubCategories(
            widget.parentId ?? '0',
            cats.isEmpty ? 0 : cats.length + 1,
          );
          cats.addAll(list);
          if (list.isEmpty) {
            _controller.loadNoData();
            return;
          }
          _controller.loadComplete();
        },
        enablePullDown: false,
        enablePullUp: true,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            return const SizedBox();
          },
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: model.state == FSLoadState.loading
              ? cats.length + 1
              : cats.length,
          itemBuilder: (context, index) {
            if (model.state == FSLoadState.loading && index == cats.length) {
              return const CategoryLoadingCheckbox();
            }

            var isCheck = false;
            final i = widget.includedCategories
                .indexWhere((element) => element.id == cats[index].id);
            if (i != -1) {
              isCheck = true;
            }
            return InkWell(
              onTap: () {
                if (cats[index].hasChildren) {
                  widget.onCallback(cats[index]);
                }
              },
              child: CategoryCheckBox(
                category: cats[index],
                isChecked: isCheck,
                onCallBack: () {
                  widget.onUpdate(cats[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
