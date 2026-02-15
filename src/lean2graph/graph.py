import html
import json

import graphviz

def format_goal_text(raw_text):
    if not raw_text:
        return ""
    safe_text = html.escape(raw_text)
    # 语法高亮
    safe_text = safe_text.replace("case ", "<b>case </b>")
    safe_text = safe_text.replace("⊢", "<font color='#b30000'><b>⊢</b></font>")
    # 简单的假设高亮 (h_xx :)
    import re

    safe_text = re.sub(r"(h[a-z_0-9\.]*) :", r"<b>\1</b> :", safe_text)

    return '<br align="left"/>'.join(safe_text.split("\n"))


def draw_complex_tree_safe(json_input, output_filename="complex_proof_fixed"):
    try:
        data = json.loads(json_input)
    except json.JSONDecodeError as e:
        print(f"JSON Parsing Error: {e}")
        print('Tip: Make sure to use raw strings: r""" ... """')
        return

    # 1. 映射策略
    node_tactic_map = {}
    node_type_map = {}

    for edge in data.get("edges", []):
        src = edge["sourceId"]
        label = edge.get("label", "")
        node_tactic_map[src] = label
        node_type_map[src] = "intermediate"

    for end_step in data.get("END", []):
        src = end_step["sourceId"]
        label = end_step.get("label", "")
        node_tactic_map[src] = label
        node_type_map[src] = "terminal"

    # 2. 初始化图表
    dot = graphviz.Digraph(comment="Proof Tree")
    dot.attr(rankdir="TB")

    dot.attr(splines="polyline")

    dot.attr("node", shape="plain", fontname="Arial")

    # 3. 绘制节点
    for node in data["nodes"]:
        nid = node["id"]
        goal_text = format_goal_text(node.get("goals", ""))
        tactic_text = node_tactic_map.get(nid, None)
        n_type = node_type_map.get(nid, "pending")

        rows = []
        # Goal
        rows.append(f"""
        <tr><td bgcolor="#ffffff" align="left" border="1" sides="b">
            <font color="#24292e" point-size="10">{goal_text}</font>
        </td></tr>
        """)

        # Tactic
        if tactic_text:
            if n_type == "terminal":
                rows.append(f"""
                <tr><td bgcolor="#e6fffa" align="center" border="1" sides="t">
                    <font color="#006600" point-size="11"><b>✔ {html.escape(tactic_text)}</b></font>
                </td></tr>
                """)
            else:
                rows.append(f"""
                <tr><td bgcolor="#f6f8fa" align="center" border="1" sides="t">
                    <font color="#24292e" point-size="11"><b>{html.escape(tactic_text)}</b></font>
                </td></tr>
                """)
        else:
            rows.append("""
            <tr><td bgcolor="#fff5f5" align="center" border="1" sides="t">
                <font color="#cb2431" point-size="9"><i>(Pending)</i></font>
            </td></tr>
            """)

        label = f"""<
        <table border="0" cellborder="0" cellspacing="0" cellpadding="6">
            {"".join(rows)}
        </table>
        >"""

        dot.node(str(nid), label=label)

    # 4. 连线
    for edge in data.get("edges", []):
        dot.edge(
            str(edge["sourceId"]),
            str(edge["targetId"]),
            color="#586069",
            penwidth="1.2",
        )

    try:
        output_path = dot.render(output_filename, format="png", view=True)
        print(f"Success! Graph generated at: {output_path}")
    except Exception as e:
        print(f"Graphviz Error: {e}")


if __name__ == "__main__":
    json_str = r"""
    {"nodes":
 [{"id": 0, "goals": "p q : Prop\n⊢ p ∧ q ↔ q ∧ p"},
  {"id": 1, "goals": "case mp\np q : Prop\n⊢ p ∧ q → q ∧ p"},
  {"id": 2, "goals": "case mpr\np q : Prop\n⊢ q ∧ p → p ∧ q"},
  {"id": 3, "goals": "case mp\np q : Prop\nh : p ∧ q\n⊢ q ∧ p"},
  {"id": 4, "goals": "case mpr\np q : Prop\nh : q ∧ p\n⊢ p ∧ q"}],
 "edges":
 [{"targetId": 1, "sourceId": 0, "label": "constructor"},
  {"targetId": 2, "sourceId": 0, "label": "constructor"},
  {"targetId": 3, "sourceId": 1, "label": "intro h"},
  {"targetId": 4, "sourceId": 2, "label": "intro h"}],
 "END": [{"sourceId": 3, "label": "exact ⟨h.2,h.1⟩"}, {"sourceId": 4, "label": "exact ⟨h.2,h.1⟩"}]}
 """
    draw_complex_tree_safe(json_str)
