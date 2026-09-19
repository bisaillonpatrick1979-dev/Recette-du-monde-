export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      ai_usage_events: {
        Row: {
          created_at: string
          credits_used: number
          estimated_cost_cad_micros: number
          feature: string
          id: number
          input_tokens: number
          model: string
          output_tokens: number
          provider: string
          user_id: string
        }
        Insert: {
          created_at?: string
          credits_used?: number
          estimated_cost_cad_micros?: number
          feature: string
          id?: number
          input_tokens?: number
          model: string
          output_tokens?: number
          provider?: string
          user_id: string
        }
        Update: {
          created_at?: string
          credits_used?: number
          estimated_cost_cad_micros?: number
          feature?: string
          id?: number
          input_tokens?: number
          model?: string
          output_tokens?: number
          provider?: string
          user_id?: string
        }
        Relationships: []
      }
      billing_accounts: {
        Row: {
          current_period_end: string | null
          stripe_customer_id: string | null
          stripe_subscription_id: string | null
          subscription_status: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          current_period_end?: string | null
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_status?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          current_period_end?: string | null
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_status?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      comment_translations: {
        Row: {
          body: string
          comment_id: string
          language_code: string
          model: string | null
          translated_at: string
        }
        Insert: {
          body: string
          comment_id: string
          language_code: string
          model?: string | null
          translated_at?: string
        }
        Update: {
          body?: string
          comment_id?: string
          language_code?: string
          model?: string | null
          translated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_translations_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "recipe_comments"
            referencedColumns: ["id"]
          },
        ]
      }
      content_reports: {
        Row: {
          comment_id: string | null
          created_at: string
          details: string | null
          id: string
          reason: Database["public"]["Enums"]["report_reason"]
          recipe_id: string | null
          reported_user_id: string | null
          reporter_id: string
        }
        Insert: {
          comment_id?: string | null
          created_at?: string
          details?: string | null
          id?: string
          reason: Database["public"]["Enums"]["report_reason"]
          recipe_id?: string | null
          reported_user_id?: string | null
          reporter_id: string
        }
        Update: {
          comment_id?: string | null
          created_at?: string
          details?: string | null
          id?: string
          reason?: Database["public"]["Enums"]["report_reason"]
          recipe_id?: string | null
          reported_user_id?: string | null
          reporter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "content_reports_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "recipe_comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_reports_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      cook_attempts: {
        Row: {
          created_at: string
          id: string
          image_path: string | null
          note: string | null
          recipe_id: string
          user_id: string
          visible: boolean
        }
        Insert: {
          created_at?: string
          id?: string
          image_path?: string | null
          note?: string | null
          recipe_id: string
          user_id: string
          visible?: boolean
        }
        Update: {
          created_at?: string
          id?: string
          image_path?: string | null
          note?: string | null
          recipe_id?: string
          user_id?: string
          visible?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "cook_attempts_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      culinary_places: {
        Row: {
          country_code: string
          created_at: string
          default_zoom: number
          id: string
          is_active: boolean
          latitude: number
          longitude: number
          name: string
          parent_id: string | null
          place_type: string
          slug: string
          summary: string | null
          updated_at: string
        }
        Insert: {
          country_code: string
          created_at?: string
          default_zoom?: number
          id?: string
          is_active?: boolean
          latitude: number
          longitude: number
          name: string
          parent_id?: string | null
          place_type: string
          slug: string
          summary?: string | null
          updated_at?: string
        }
        Update: {
          country_code?: string
          created_at?: string
          default_zoom?: number
          id?: string
          is_active?: boolean
          latitude?: number
          longitude?: number
          name?: string
          parent_id?: string | null
          place_type?: string
          slug?: string
          summary?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "culinary_places_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "culinary_places"
            referencedColumns: ["id"]
          },
        ]
      }
      entitlements: {
        Row: {
          ai_credits_used: number
          ai_monthly_credits: number
          period_end: string
          period_start: string
          plan_code: string
          updated_at: string
          user_id: string
        }
        Insert: {
          ai_credits_used?: number
          ai_monthly_credits?: number
          period_end?: string
          period_start?: string
          plan_code?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          ai_credits_used?: number
          ai_monthly_credits?: number
          period_end?: string
          period_start?: string
          plan_code?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      favorites: {
        Row: {
          created_at: string
          recipe_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          recipe_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          recipe_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      follows: {
        Row: {
          created_at: string
          follower_id: string
          following_id: string
        }
        Insert: {
          created_at?: string
          follower_id: string
          following_id: string
        }
        Update: {
          created_at?: string
          follower_id?: string
          following_id?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          actor_id: string | null
          comment_id: string | null
          created_at: string
          id: string
          payload: Json
          read_at: string | null
          recipe_id: string | null
          type: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Insert: {
          actor_id?: string | null
          comment_id?: string | null
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          recipe_id?: string | null
          type: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Update: {
          actor_id?: string | null
          comment_id?: string | null
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          recipe_id?: string | null
          type?: Database["public"]["Enums"]["notification_type"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "recipe_comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_path: string | null
          bio: string | null
          country_code: string | null
          created_at: string
          display_name: string | null
          id: string
          updated_at: string
          username: string | null
        }
        Insert: {
          avatar_path?: string | null
          bio?: string | null
          country_code?: string | null
          created_at?: string
          display_name?: string | null
          id: string
          updated_at?: string
          username?: string | null
        }
        Update: {
          avatar_path?: string | null
          bio?: string | null
          country_code?: string | null
          created_at?: string
          display_name?: string | null
          id?: string
          updated_at?: string
          username?: string | null
        }
        Relationships: []
      }
      recipe_comments: {
        Row: {
          body: string
          created_at: string
          deleted_at: string | null
          id: string
          language_code: string
          parent_comment_id: string | null
          recipe_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          language_code?: string
          parent_comment_id?: string | null
          recipe_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          language_code?: string
          parent_comment_id?: string | null
          recipe_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_comments_parent_comment_id_fkey"
            columns: ["parent_comment_id"]
            isOneToOne: false
            referencedRelation: "recipe_comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recipe_comments_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_ingredients: {
        Row: {
          created_at: string
          id: number
          name: string
          note: string | null
          position: number
          quantity: number | null
          recipe_id: string
          unit: string | null
        }
        Insert: {
          created_at?: string
          id?: number
          name: string
          note?: string | null
          position?: number
          quantity?: number | null
          recipe_id: string
          unit?: string | null
        }
        Update: {
          created_at?: string
          id?: number
          name?: string
          note?: string | null
          position?: number
          quantity?: number | null
          recipe_id?: string
          unit?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "recipe_ingredients_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_likes: {
        Row: {
          created_at: string
          recipe_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          recipe_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          recipe_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_likes_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_locations: {
        Row: {
          created_at: string
          is_primary: boolean
          place_id: string
          recipe_id: string
          relation: string
        }
        Insert: {
          created_at?: string
          is_primary?: boolean
          place_id: string
          recipe_id: string
          relation?: string
        }
        Update: {
          created_at?: string
          is_primary?: boolean
          place_id?: string
          recipe_id?: string
          relation?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_locations_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "culinary_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recipe_locations_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_ratings: {
        Row: {
          created_at: string
          rating: number
          recipe_id: string
          review: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          rating: number
          recipe_id: string
          review?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          rating?: number
          recipe_id?: string
          review?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_ratings_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_steps: {
        Row: {
          created_at: string
          id: number
          image_path: string | null
          instruction: string
          position: number
          recipe_id: string
          timer_seconds: number | null
        }
        Insert: {
          created_at?: string
          id?: number
          image_path?: string | null
          instruction: string
          position: number
          recipe_id: string
          timer_seconds?: number | null
        }
        Update: {
          created_at?: string
          id?: number
          image_path?: string | null
          instruction?: string
          position?: number
          recipe_id?: string
          timer_seconds?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "recipe_steps_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipe_translations: {
        Row: {
          description: string | null
          ingredients: Json
          language_code: string
          model: string | null
          recipe_id: string
          steps: Json
          title: string
          translated_at: string
        }
        Insert: {
          description?: string | null
          ingredients?: Json
          language_code: string
          model?: string | null
          recipe_id: string
          steps?: Json
          title: string
          translated_at?: string
        }
        Update: {
          description?: string | null
          ingredients?: Json
          language_code?: string
          model?: string | null
          recipe_id?: string
          steps?: Json
          title?: string
          translated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_translations_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipes: {
        Row: {
          authenticity: Database["public"]["Enums"]["recipe_authenticity"]
          author_id: string
          category: string | null
          cook_minutes: number | null
          country_code: string | null
          cover_image_path: string | null
          created_at: string
          description: string | null
          difficulty: Database["public"]["Enums"]["recipe_difficulty"] | null
          id: string
          prep_minutes: number | null
          published_at: string | null
          region: string | null
          servings: number | null
          source_language: string
          status: Database["public"]["Enums"]["recipe_status"]
          title: string
          updated_at: string
        }
        Insert: {
          authenticity?: Database["public"]["Enums"]["recipe_authenticity"]
          author_id: string
          category?: string | null
          cook_minutes?: number | null
          country_code?: string | null
          cover_image_path?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["recipe_difficulty"] | null
          id?: string
          prep_minutes?: number | null
          published_at?: string | null
          region?: string | null
          servings?: number | null
          source_language?: string
          status?: Database["public"]["Enums"]["recipe_status"]
          title: string
          updated_at?: string
        }
        Update: {
          authenticity?: Database["public"]["Enums"]["recipe_authenticity"]
          author_id?: string
          category?: string | null
          cook_minutes?: number | null
          country_code?: string | null
          cover_image_path?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["recipe_difficulty"] | null
          id?: string
          prep_minutes?: number | null
          published_at?: string | null
          region?: string | null
          servings?: number | null
          source_language?: string
          status?: Database["public"]["Enums"]["recipe_status"]
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      user_blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: []
      }
      user_preferences: {
        Row: {
          country_code: string
          currency_code: string
          language_code: string
          measurement_system: Database["public"]["Enums"]["measurement_system"]
          temperature_unit: Database["public"]["Enums"]["temperature_unit"]
          translate_comments: boolean
          translate_recipes: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          country_code?: string
          currency_code?: string
          language_code?: string
          measurement_system?: Database["public"]["Enums"]["measurement_system"]
          temperature_unit?: Database["public"]["Enums"]["temperature_unit"]
          translate_comments?: boolean
          translate_recipes?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          country_code?: string
          currency_code?: string
          language_code?: string
          measurement_system?: Database["public"]["Enums"]["measurement_system"]
          temperature_unit?: Database["public"]["Enums"]["temperature_unit"]
          translate_comments?: boolean
          translate_recipes?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_recipe_with_content: {
        Args: {
          p_authenticity?: Database["public"]["Enums"]["recipe_authenticity"]
          p_category?: string
          p_cook_minutes?: number
          p_country_code?: string
          p_description?: string
          p_difficulty?: Database["public"]["Enums"]["recipe_difficulty"]
          p_ingredients?: Json
          p_prep_minutes?: number
          p_region?: string
          p_servings?: number
          p_source_language?: string
          p_status?: Database["public"]["Enums"]["recipe_status"]
          p_steps?: Json
          p_title: string
        }
        Returns: string
      }
    }
    Enums: {
      measurement_system: "metric" | "imperial" | "cups"
      notification_type:
        | "comment"
        | "rating"
        | "like"
        | "follow"
        | "cook_attempt"
        | "system"
      recipe_authenticity: "traditional" | "adapted" | "fusion"
      recipe_difficulty: "easy" | "medium" | "hard"
      recipe_status: "draft" | "published" | "archived"
      report_reason:
        | "spam"
        | "abuse"
        | "copyright"
        | "unsafe"
        | "misinformation"
        | "other"
      temperature_unit: "c" | "f"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      measurement_system: ["metric", "imperial", "cups"],
      notification_type: [
        "comment",
        "rating",
        "like",
        "follow",
        "cook_attempt",
        "system",
      ],
      recipe_authenticity: ["traditional", "adapted", "fusion"],
      recipe_difficulty: ["easy", "medium", "hard"],
      recipe_status: ["draft", "published", "archived"],
      report_reason: [
        "spam",
        "abuse",
        "copyright",
        "unsafe",
        "misinformation",
        "other",
      ],
      temperature_unit: ["c", "f"],
    },
  },
} as const
